require 'spec_helper'
require 'securerandom'
require 'tempfile'
require 'pogoplug/client'
require 'pogoplug/service_client'

describe PogoPlug::ServiceClient do
  NAME = "Pogoplug Cloud"

  PATH = ::File.expand_path('../../test_file.txt', __FILE__)
  CONTENT = IO.read(PATH)

  PATH_2 = ::File.expand_path('../../test_file_2.txt', __FILE__)
  CONTENT_2 = IO.read(PATH_2)

  PDF_PATH = ::File.expand_path('../../sample-file.pdf', __FILE__)

  def generate_name
    SecureRandom.hex
  end

  before do
    client = PogoPlug::Client.new("https://service.pogoplug.com/")
    @username = "gem_test_user@mailinator.com"
    @password = "p@ssw0rd"
    @token = client.login(@username, @password)
    @device = client.devices.first { |d| d.name == NAME }
    raise 'there should have been a device here' if @device.nil?
    @client = @device.services.first.client
    name = generate_name
    @parent = @client.create_directory(name)
  end

  after do
    unless @parent_removed
      @client.delete(@parent.id)
    end
  end

  it "should create a directory" do
    name = generate_name
    directory = @client.create_directory(name, @parent.id)
    expect(directory.name).to eq(directory.name)
    expect(directory.id).not_to be_nil
  end

  it 'should upload a file' do
    ::File.open(PATH) do |f|
      name = "#{generate_name}.txt"
      file = @client.create_file(name, @parent.id, f)
      expect(@client.download(file)).to eq(CONTENT)
    end
  end

  it 'should download a file to an specific path' do
    ::File.open(PATH) do |f|
      name = "#{generate_name}.txt"
      file = @client.create_file(name, @parent.id, f)

      destination = Tempfile.new("test")
      @client.download_to(file, destination.path)
      expect(IO.read(destination.path)).to eq(CONTENT)
    end
  end

  it "should get a file by it' id" do
    name = generate_name
    directory = @client.create_directory(name, @parent.id)
    stored = @client.find_by_id!(directory.id)
    expect(stored.name).to eq(name)
    expect(stored.id).to eq(directory.id)
  end

  it "should allow create_entity to be called twice" do
    name = "#{generate_name}.txt"

    result = ::File.open(PATH) do |f|
      @client.create_file(name, @parent.id, f)
    end

    updated = ::File.open(PATH_2) do |f|
      @client.create_entity(result, f)
    end

    expect(result.id).to eq(updated.id)
    expect(@parent.id).to eq(updated.parent_id)
    expect(@client.download(result)).to eq(CONTENT_2)
  end

  it "should delete a file correctly" do
    name = "#{generate_name}.txt"

    result = ::File.open(PATH) do |f|
      @client.create_file(name, @parent.id, f)
    end

    @client.delete(result.id)

    expect { @client.find_by_id!(result.id) }.to raise_error(PogoPlug::NotFoundError)
  end

  it "should ignore the delete if it does not exist" do
    name = generate_name
    item = @client.create_directory(name, @parent.id)

    @client.delete(item.id)
    expect(@client.delete_if_exists(item.id)).to be_nil
  end

  it "should delete the item if it exists" do
    name = generate_name
    item = @client.create_directory(name, @parent.id)

    @client.delete_if_exists(item.id)
    expect(@client.find_by_id(item.id)).to be_nil
  end

  it "should list files from directory" do
    first = generate_name
    second = generate_name

    @client.create_directory(first, @parent.id)
    @client.create_directory(second, @parent.id)

    listing = @client.list_files(@parent.id)

    expect(listing.find { |f| f.name == first }).not_to be_nil
    expect(listing.find { |f| f.name == second }).not_to be_nil
    expect(listing.total_count).to eq(2)
    expect(listing.offset).to eq(0)
  end

  it "should create the directory if it is not there" do
    name = generate_name
    result = @client.create_entity_if_needed(name, @parent.id)
    expect(result.name).to eq(name)
    expect(result.parent_id).to eq(@parent.id)
  end

  it "should return the directory itself is it is already there" do
    name = generate_name
    result = @client.create_directory(name, @parent.id)
    other = @client.create_entity_if_needed(name, @parent.id)
    expect(other.id).to eq(result.id)
  end

  it "should create a file if it is not there already" do
    name = "#{generate_name}.txt"

    result = ::File.open(PATH) do |f|
      @client.create_entity_if_needed(name, @parent.id, f)
    end

    expect(@client.download(result)).to eq(CONTENT)
  end

  it "should update the file if it is already there" do
    name = "#{generate_name}.txt"

    result = ::File.open(PATH) do |f|
      @client.create_file(name, @parent.id, f)
    end

    updated = ::File.open(PATH_2) do |f|
      @client.create_entity_if_needed(name, @parent.id, f)
    end

    expect(updated.id).to eq(result.id)
    expect(updated.parent_id).to eq(@parent.id)
    expect(@client.download(result)).to eq(CONTENT_2)
  end

  it "should rename the file inside the same folder" do
    name = "some file.txt"
    other_name = "other file.txt"

    result = ::File.open(PATH) do |f|
      @client.create_file(name, @parent.id, f)
    end

    @client.move(result.id, @parent.id, other_name)

    moved = @client.find_by_name(other_name, @parent.id)

    expect(moved.id).to eq(result.id)
    expect(@client.find_by_name(name, @parent.id)).to be_nil
    expect(@client.download(moved)).to eq(CONTENT)
  end

  it "should rename the file across folders" do
    name = "file.txt"
    other_folder = 'other folder'

    result = ::File.open(PATH) do |f|
      @client.create_file(name, @parent.id, f)
    end

    destination = @client.create_directory(other_folder, @parent.id)

    @client.move(result.id, destination.id, result.name)

    moved = @client.find_by_name!(result.name, destination.id)

    expect(moved.id).to eq(result.id)
    expect(@client.find_by_name(name, @parent.id)).to be_nil
    expect(@client.download(moved)).to eq(CONTENT)
  end

  it "should delete an item by it's name" do
    name = "file.txt"

    result = ::File.open(PATH) do |f|
      @client.create_file(name, @parent.id, f)
    end

    @client.delete_by_name(name, @parent.id)

    expect(@client.find_by_id(result.id)).to be_nil
  end

  it "should not do anything if trying to delete a file that does not exist" do
    expect(@client.delete_by_name("file.txt", @parent.id)).to be_nil
  end

  it 'should delete the created top folder' do
    @parent_removed = true
    expect(@client.delete_by_name(@parent.name)).to be_true
  end

  it "should download a binary file correctly" do
    name = 'something.pdf'
    result = ::File.open(PDF_PATH) do |f|
      @client.create_file(name, @parent.id, f)
    end

    destination = Tempfile.new("test")
    @client.download_to(result, destination.path)
    expect(::File.stat(destination.path).size).to eq(::File.stat(PDF_PATH).size)
  end

end