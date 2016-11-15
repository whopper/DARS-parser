Great documentation is vitally important to the quality and usability of any software, and Puppet modules are certainly no exception. While this may be a no-brainer, the real challenge lies in maintaining docs that don’t lag behind the latest release of a project. We created Puppet Strings to help module authors deal with this challenge by rendering user friendly documentation from Puppet source code. We have just released a major revision of Puppet Strings with new features and fixes for many issues reported by early users. 


Even if you don’t consider yourself a Puppet module developer, read on. Higher quality documentation through Puppet Strings is valuable to everyone in the worldwide Puppet community. An easy way to contribute back to the modules you use everyday is to add Strings content to them.


Strings is a YARD-based documentation tool for Puppet code and extensions that are written in Puppet and Ruby. Given some simple in-code comments containing YARD tags, Strings generates consistent HTML or JSON documentation for all of your classes, Puppet 3.x/4.x API functions, Puppet language functions, resource types, providers, Ruby classes, and Ruby methods.


This post will walk you through the basics of using Strings to document all of the pieces of a Puppet module.


## Setup: Installing Strings


In this example, we’ll install the Strings Rubygem with bundler. (Note that the gem can also be installed system-wide using the **_puppet_gem_** or **_gem_** providers.)


To use Puppet Strings in your module, simply add the following to your module’s Gemfile, and then run **_bundle install_**:


    > cat Gemfile
    source ENV['GEM_SOURCE'] || "https://rubygems.org"
    gem "puppet", ENV['PUPPET_GEM_VERSION'] || '~> 4.7.0'
    gem 'puppet-strings'
    gem 'rake'


Strings is compatible with Puppet 3.8 and above, and in this example we’ll be using the latest release, Puppet 4.8. Notes about differences with Puppet 3.8 will be specifically called out throughout this post.


## Documenting Puppet Classes and Defined Types and Running Strings


It is straightforward to document classes and user defined types using Puppet Strings.


As is the case with anything that can be documented with YARD, we’ll be working with a series of comments that make up the YARD **_docstring_**. This can include free-form text which is treated as a high-level ‘overview’ for the class, as well as any number of YARD **_tags_** which hold semantic metadata for various aspects of the code. These tags allow us to add this data to the code without worrying about presentation.


    # An example class.
    #
    # This is an example of how to document a Puppet class:
    #
    # @example Declaring the class
    #   include example_class
    #
    # @param first The first parameter for this class.
    # @param second The second parameter for this class.
    class example_class(
      String $first  = $example_class::params::first_arg,
      Integer $second = $example_class::params::second_arg,
    ) inherits example_class::params {
      # ...
    }


The first few lines of this block of comments, which are not prefixed with any tags, constitute the description of the class. 


Next, we have our first YARD tag. The **_@example_** tag can be used to add usage examples to any Puppet or Ruby code.


    # @example Declaring the class
    #    include example_class


The string following the tag is an optional title, which is displayed prominently with the example in the final output.


Finally, we have **_@param_** tags for each of the parameters of the class. 


    # @param first The first parameter for this class.
    # @param second The second parameter for this class.


The first word after the tag is the name of the parameter, and the following string describes its purpose. Since Puppet 4.x is a typed language, Strings automatically uses the parameter type information from the code to document the parameter types. If no type is specified in code, the parameter defaults to the type **_Any_**.


Since Puppet 3.x does not support typed parameters, the **_@param_** tags should include the expected type of the parameter, like so:


    # @param [String] first The first parameter for this class.
    # @param [Integer] second The second parameter for this class.


Defined types are documented in exactly the same way as classes:


    # An example defined type.
    #
    # This is an example of how to document a defined type.
    # @param ports The array of port numbers to use.
    define example_type(
       Array[Integer] $ports = []
    ) {
      # ...
    }


Now that we’ve got some documented code, we can run Strings to generate the documentation in either HTML or JSON. I’ve separated this code into two files in my module: class.pp and defined_type.pp:
    
    mymodule > tree
    .
      |----- manifests
            |----- class.pp
             ----- defined_type.pp


To generate HTML documentation, we’ll invoke the following command from the top level of the module:


    bundle exec puppet strings generate ./manifests/*.pp
 
This results in the creation of a **_docs_** directory and an **_index.html_** file, which we can view in a browser. Using the sidebar on the opened page to view the generated documentation for the class, we see:









Strings automatically groups documented code by type, allowing each to be browsed separately. Here we see that we have Puppet classes and defined types available to view.


Alternatively, you can generate the same documentation as JSON. This can be useful for handling or displaying the data with your own custom applications. To generate JSON, run the following command:


    bundle exec puppet strings generate ./manifests/*.pp --emit-json output.json


This results in a file, **_output.json**_, populated with all of the parsed data organized similarly to the HTML navigation categories above:


    {
        “Puppet_classes”: [
            “name”: “example_class”,
            “file”: “manifests/class.pp”,
            “line”: 10,
            “inherits”: “example_class::params”,
            “docstring”: {
                “text”: “An example class.\n\nThis is an example of how to document a Puppet class.”
                “tags”: [
	         {
 	             “tag_name”: “example”,
 	             “text”: “include example_class”,
 	             “name”: “Declaring the class”,




                     },
 	         {
 	             “tag_name”: “param”,
 	             “text”: “The first parameter for the class.”,
 	             “types”: [
   		      “String”
		  ],
		  “name”: “first”
                     },
                ]
	}
        ]
       …
    }


See the Strings JSON schema for more information.


## Documenting Puppet Functions


The syntax for documenting Puppet functions is very similar to our above examples of documenting Puppet classes, with a few key differences. We’ll start with a function written in the Puppet language:


    # An example function written in Puppet.
    # @param name the name to say hello to.
    # @return [String] Returns a string.
    # @example Calling the function
    #    example(‘world’)
    function example(String $name) {
        “hello, $name”
    }


To document such a function, provide a docstring before the function definition, like in the above example. Strings automatically uses the parameter type information from the function’s parameter list to document the parameter type.


In addition, notice the **_@return_** tag, which should always be included to document what a function returns.


Documentation can be added to functions using the Puppet 4.x API by adding a docstring before the **_create_function_** call and any **_dispatch_** calls:

    # Subtracts two things.
    Puppet::Functions.create_function(:subtract) do
        # Subtracts two integers.
        # @param x The first integer.
        # @param y The second integer.
        # @return [Integer] Returns x - y.
        # @example Subtracting two integers.
        #   subtract(5, 1) => 4
        dispatch :subtract_ints do
          param 'Integer', :x
          param 'Integer', :y
        end


        # Subtracts two arrays.
        # @param x The first array.
        # @param y The second array.
        # @return [Array] Returns x - y.
        # @example Subtracting two arrays.
        #   subtract([3, 2, 1], [1]) => [3, 2]
        dispatch :subtract_arrays do
          param 'Array', :x
          param 'Array', :y
        end


        def subtract_ints(x, y)
          x - y
        end


         def subtract_arrays(x, y)
          x - y
        end
    end

The first comment before the call to **_create_function_**, “subtracts two things”, acts as the top-level docstring for the entire function. This provides a general description for the function as a whole.


Next, we have the two dispatches, which are signature overloads. These can be documented separately by adding a docstring with tags above each. Strings displays each as a separate signature, both in the HTML and JSON output.


Note that Strings automatically uses the parameter and return type information from the **_dispatch_** block to document the parameter types. You should only document your parameter types when the Puppet 4.x function contains no **_dispatch_** calls.


Each overload can include text to describe its purpose, as shown in the example above with “subtracts two integers” and “subtracts two arrays”.


For more information on the Puppet 4.x function API, see https://github.com/puppetlabs/puppet-specifications/blob/master/language/func-api.md#defining-a-typed-dispatch


##### 3.x functions are documented differently:


    Puppet::Parser::Functions::newfunction(
      :raise,
      :type => :statement,
      :arity => 1,
      :doc => <<-DOC
    Raises a `Puppet::Error` exception.
    @param [String, Integer] message The exception message.
    @return [Undef]
    @example Raise an exception.
      raise('nope')
    DOC
    ) do |args|
      raise Puppet::Error, args[0]
    end


The YARD docstring must be written inside of a heredoc within the **_:doc_** parameter of the **_Puppet::Parser::Functions::newfunction_** call. While clunkier in this respect, the documentation markup syntax is otherwise the same. 3.x functions do not have dispatches or allow multiple overloads, so there will only be one set of parameters and one return type.


Assuming we’ve placed these functions in **_lib/puppet/functions/4x_function.rb_** and **_lib/puppet/parser/functions/3x_function.rb_** respectively, we can generate documentation for them by running the following command: 


    bundle exec puppet strings generate ./lib/puppet/**/*.rb


This will run Strings against all files ending with the **_.rb_** extension anywhere under **_./lib/puppet_** on the filesystem.

## Documenting Resource Types and Providers


The last two Puppet constructs we’ll document are types and providers. These are fairly easy to document as Strings automatically detects most of the important bits. We’ll start with a simple resource type:

    # @!puppet.type.param [value1, value2, value3] my_param Documentation for a dynamic parameter.
    # @!puppet.type.property [foo, bar, baz] my_prop Documentation for a dynamic property.
    Puppet::Type.newtype(:database) do
      desc <<-DESC
    An example resource type.
    @example Using the type.
        Example { foo:
            Param => ‘hi’
        }
    DESC


      feature :encryption, 'The provider supports encryption.', methods: [:encrypt]
      newparam(:address) do
        isnamevar
        desc 'The database server name.'
      end


      newproperty(:file) do
        desc 'The database file to use.'
      end


      newproperty(:log_level) do
        desc 'The log level to use.'
        newvalue(:debug)
        newvalue(:warn)
        newvalue(:error)
      end
    end

Perhaps the most interesting bits here are the first comments before the call to newtype:


    # @!puppet.type.param [value1, value2, value3] my_param Documentation for a dynamic parameter.
    # @!puppet.type.property [foo, bar, baz] my_prop Documentation for a dynamic property.


If your resource type includes parameters or properties which are dynamically created at runtime, you must document them with the **_@!puppet.type.param_** and **_@!puppet.type.property_** directives (see the end of this post to [learn more](#learn-more). This is necessary because Strings does not evaluate Ruby code, so it cannot detect dynamic attributes.


Apart from dynamic attributes, the only other necessary code for complete documentation are descriptions for each parameter, property, and the resource type itself. These must be passed to the **_desc_** method. Each description can include other tags as well, including examples.


Every other method call present in the type is automatically included and documented by Strings, and each parameter or property is updated accordingly in the final documentation. This includes calls to **_defaultto_**, **_newvalue_**, **_aliasvalue_** and so on.


Providers are processed a similar way:


    Puppet::Type.type(:database).provide :linux do
        confine ‘osfamily’ => ‘linux’
        defaultfor ‘osfamily’ => ‘linux’
        commands :database => ‘/usr/bin/database’


        Desc ‘An example provider.’
    end


All provider methods including **_confine_**, **_defaultfor_**, and **_commands_** are automatically parsed and documented by Strings. The **_desc_** method is used to generate the docstring and can include tags such as **_@example_** if written as a heredoc.


## Generating Documentation for an Entire Module


We now have a module full of manifests, functions, types, and providers. By running the following command we can instruct Strings to generate documentation for every file ending with the extension **_.pp_** or **_.rb_**:


    bundle exec puppet strings generate ./**/*(.pp|.rb)


This results in a browsable **__index.html file_** in the **_docs_** directory which can be navigated to view each of the files which we’ve just documented. Hurray!


Of course, the **_--emit-json <FILE>_** or **_--emit-json-stdout_** options could also be used to produce JSON rather than HTML. In either case, with these simple steps and minimal code changes, we’ve fully documented our module! 


Since the documentation is embedded with the code itself, it’s much easier to remember to update it in step with the code as it changes. No more out of date documentation! In addition, by using Strings, we’ve also gained a free way to generate aesthetically pleasing HTML documentation. Strings can even run a web server to serve your Puppet docs for you!


For more in-depth information about puppet-strings, check out the [readme](https://github.com/puppetlabs/puppet-strings/blob/master/README.md). The YARD [getting started guide](http://www.rubydoc.info/gems/yard/file/docs/GettingStarted.md) and [tag overview](http://www.rubydoc.info/gems/yard/file/docs/Tags.md tag overview) guides are also recommended reading for advanced users. In addition, we’re working on a few more blog posts and a comprehensive style guide for the project, so stay tuned!


*William Hopper is a software engineer at Puppet. Since 2012 he’s worked on core open-source projects like Puppet, Facter, and more recently Strings.


## Learn more


* In-depth information about puppet-strings in the [readme](https://github.com/puppetlabs/puppet-strings/blob/master/README.md).
* YARD [getting started guide](http://www.rubydoc.info/gems/yard/file/docs/GettingStarted.md) and [tag overview](http://www.rubydoc.info/gems/yard/file/docs/Tags.md) guides for advanced users. 
