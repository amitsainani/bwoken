require 'bwoken/coffeescript'
require 'stringio'

require 'spec_helper'

describe Bwoken::Coffeescript do
  let(:subject) { Bwoken::Coffeescript.new('foo/bar.js') }
  describe '.source_folder' do
    it "should match '<bwoken_path>/coffeescript'" do
      bwoken_path = stub_out(Bwoken, :path, 'bar')
      Bwoken::Coffeescript.source_folder.should == "#{bwoken_path}/coffeescript"
    end
  end

  describe '.destination_folder' do
    it "should equal '<bwoken_tmp_path>/javascript'" do
      Bwoken.stub(:path => '')
      bwoken_tmp_path = stub_out(Bwoken, :tmp_path, 'bar')
      subject.destination_folder.should == "#{bwoken_tmp_path}/javascript/foo"
    end
  end

  describe '.test_files' do
    it 'wildcard includes coffeescript files' do
      Bwoken::Coffeescript.stub(:source_folder => 'z_source_folder')
      Bwoken::Coffeescript.test_files.should == 'z_source_folder/**/*.coffee'
    end
  end

  describe '.compile_all' do
    it 'calls make on each new instance of a coffeescript file' do
      Dir.should_receive(:[]).with('foo/*.coffee').and_return(['foo/bar.coffee'])
      Bwoken::Coffeescript.stub(:test_files => 'foo/*.coffee')

      coffee_stub = double('coffeescript')
      coffee_stub.should_receive(:make)
      Bwoken::Coffeescript.should_receive(:new).and_return(coffee_stub)

      Bwoken::Coffeescript.compile_all
    end
  end

  describe '#initialize filename' do
    it 'sets @source_file to filename' do
      filename = 'bazzle'
      Bwoken::Coffeescript.new(filename).instance_variable_get('@source_file').should == filename
    end
  end

  describe '#destination_file' do
    it 'is the path to the desired output (.js) file' do
      filename = 'bazzle.coffee'
      stub_folder = 'stub_folder'
      subject = Bwoken::Coffeescript.new(filename)
      subject.stub(:destination_folder => stub_folder)
      subject.destination_file.should == "stub_folder/bazzle.js"
    end
  end

  describe '#make' do
    before do
      FileUtils.stub(:mkdir_p)
      subject.stub(:destination_folder => 'foo')
      subject.stub(:compile)
      subject.stub(:precompile)
      subject.stub(:save)
    end

    it 'makes the destination folder' do
      FileUtils.should_receive(:mkdir_p).with('foo')
      subject.make
    end

    it 'compiles' do
      subject.should_receive(:compile).once
      subject.make
    end
  end

  describe '#compile' do
    it "compiles js to coffeescript" do
      subject.stub(:source_contents => 'a = 1')
      subject.compile.should match /var/
    end
  end

  describe '#capture_imports raw_javascript' do
    let(:test_js) {"var foo;\n#import bazzle.js\nvar bar;"}
    it "collects the #import tag" do
      subject.capture_imports(test_js)
      subject.import_strings.should == ["#import bazzle.js"]
    end
  end

  describe '#remove_imports raw_javascript' do
    let(:test_js) {"var foo;\n#import bazzle.js\nvar bar;"}
    it 'removes the #import tag' do
      subject.remove_imports(test_js).should == "var foo;\n\nvar bar;"
    end
  end

  describe '#precompile' do
    before do
      subject.stub(:capture_imports)
      subject.stub(:remove_imports)
    end

    it 'calls capture_imports' do
      subject.should_receive(:capture_imports).with('foo')
      subject.precompile 'foo'
    end

    it 'calls remove_imports' do
      subject.should_receive(:remove_imports).with('foo')
      subject.precompile 'foo'
    end

  end

  describe '#save javascript' do
    it 'saves the javascript to the destination_file' do
      stringio = StringIO.new
      destination_file = 'bazzle/bar.js'
      subject.stub(:destination_file => destination_file)

      File.should_receive(:open).
        any_number_of_times.
        with(destination_file, 'w').
        and_yield(stringio)

      subject.save 'some javascript'
      stringio.string.strip.should == 'some javascript'
    end

    context 'with import_strings' do
      it 'saves the import_strings first' do
        stringio = StringIO.new
        destination_file = 'bazzle/bar.js'
        subject.stub(:destination_file => destination_file)
        subject.import_strings = ["#import foo.js", "#import bar.js"]

        File.should_receive(:open).
          any_number_of_times.
          with(destination_file, 'w').
          and_yield(stringio)

        subject.save 'some javascript'
        stringio.string.strip.should == "#import foo.js\n#import bar.js\nsome javascript"
      end

    end

  end

end
