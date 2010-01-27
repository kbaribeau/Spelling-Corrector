require 'lib/spelling/spelling'

PROJECT_DIR = File.expand_path(File.dirname(__FILE__) + "../../../../")

describe SpellingCorrector do
	it "should correct various words" do
		language_model = LanguageModelBuilder.new
		language_model.build_from_filesystem(PROJECT_DIR + "/big.txt")
		corrector = SpellingCorrector.new(language_model, WordEditor.new)
		
		corrector.correct("acess").should == "access"
		corrector.correct("access").should == "access"
		corrector.correct("heare").should == "heard"
		corrector.correct("carr").should == "carry"
		corrector.correct("forbiden").should == "forbidden"
		corrector.correct("acesing").should == "causing"
		corrector.correct("hoyse").should == "house"
	end

	it "should apply second order edits" do
		editor = WordEditor.new
		language_model = LanguageModelBuilder.new
		class << language_model 
			def [] x
				return 1 if x == 'a'
				0
			end
		end
		corrector = SpellingCorrector.new(language_model, nil)
		class << corrector
			def apply_all_edits(word)
				return ['a'] if @called
				@called = true
				['b']
			end
		end

		result = corrector.correct("word")

		result.should == 'a'
	end

	it "should apply all edits" do
		editor = WordEditor.new
		class << editor
			def delete_single_char(word)
				['a'] 
			end
			def transpose_letters(word) 
				['c'] 
			end
			def find_one_letter_typeos(word)
				['d'] 
			end
			def add_single_char(word)
				['b']
			end
		end

		corrector = SpellingCorrector.new(nil, editor)
		result = corrector.apply_all_edits('foo')

		result.should == ['a', 'b', 'c', 'd'] #FIXME: order shouldn't be enforced
	end

	context "when finding a match" do
		it "should return the best match" do
			model = {'a' => 1, 'b' => 2, 'c' => 1}
			corrector = SpellingCorrector.new(model, nil)

			result = corrector.find_match(['a', 'b', 'f'])

			result.should == 'b'
		end
	end
end

describe WordEditor do
	before(:each) do
		@editor = WordEditor.new
	end

	it "should delete a single character" do
		@editor.delete_single_char("word").should == ["ord", "wrd", "wod", "wor"]	
		@editor.delete_single_char("asdfjkl").should == 
			["sdfjkl", "adfjkl", "asfjkl", "asdjkl", "asdfkl", "asdfjl", "asdfjk"]	
	end

	it "should transpose every set of two letters" do
		@editor.transpose_letters("word").should == ["owrd", "wrod", "wodr"]
		@editor.transpose_letters("asdfjkl").should == ["sadfjkl", "adsfjkl", "asfdjkl", "asdjfkl", "asdfkjl", "asdfjlk"]
	end

	it "should only add one letter typeos" do
		@editor.find_one_letter_typeos("wo").should ==
			["ao", "bo", "co", "do", "eo", "fo", "go", "ho", "io", "jo", "ko", "lo", "mo", "no", "oo", "po", "qo", "ro", "so", "to", "uo", "vo", "xo", "yo", "zo", 
			"wa", "wb", "wc", "wd", "we", "wf", "wg", "wh", "wi", "wj", "wk", "wl", "wm", "wn", "wp", "wq", "wr", "ws", "wt", "wu", "wv", "ww", "wx", "wy", "wz"]
		@editor.find_one_letter_typeos("wor").should ==
			["aor", "bor", "cor", "dor", "eor", "for", "gor", "hor", "ior", "jor", "kor", "lor", "mor", "nor", "oor", "por", "qor", "ror", "sor", "tor", "uor", "vor", "xor", "yor", "zor",
			"war", "wbr", "wcr", "wdr", "wer", "wfr", "wgr", "whr", "wir", "wjr", "wkr", "wlr", "wmr", "wnr", "wpr", "wqr", "wrr", "wsr", "wtr", "wur", "wvr", "wwr", "wxr", "wyr", "wzr",
			"woa", "wob", "woc", "wod", "woe", "wof", "wog", "woh", "woi", "woj", "wok", "wol", "wom", "won", "woo", "wop", "woq", "wos", "wot", "wou", "wov", "wow", "wox", "woy", "woz"]
	end

	it "should add letters" do
		@editor.add_single_char("wo").should ==
			['awo', 'bwo', 'cwo', 'dwo', 'ewo', 'fwo', 'gwo', 'hwo', 'iwo', 'jwo', 'kwo', 'lwo', 'mwo', 'nwo', 'owo', 'pwo', 'qwo', 'rwo', 'swo', 'two', 'uwo', 'vwo', 'wwo', 'xwo', 'ywo', 'zwo',
			'wao', 'wbo', 'wco', 'wdo', 'weo', 'wfo', 'wgo', 'who', 'wio', 'wjo', 'wko', 'wlo', 'wmo', 'wno', 'woo', 'wpo', 'wqo', 'wro', 'wso', 'wto', 'wuo', 'wvo', 'wwo', 'wxo', 'wyo', 'wzo',
			'woa', 'wob', 'woc', 'wod', 'woe', 'wof', 'wog', 'woh', 'woi', 'woj', 'wok', 'wol', 'wom', 'won', 'woo', 'wop', 'woq', 'wor', 'wos', 'wot', 'wou', 'wov', 'wow', 'wox', 'woy', 'woz']

		@editor.add_single_char("wor").should ==
			['awor', 'bwor', 'cwor', 'dwor', 'ewor', 'fwor', 'gwor', 'hwor', 'iwor', 'jwor', 'kwor', 'lwor', 'mwor', 'nwor', 'owor', 'pwor', 'qwor', 'rwor', 'swor', 'twor', 'uwor', 'vwor', 'wwor', 'xwor', 'ywor', 'zwor',
			'waor', 'wbor', 'wcor', 'wdor', 'weor', 'wfor', 'wgor', 'whor', 'wior', 'wjor', 'wkor', 'wlor', 'wmor', 'wnor', 'woor', 'wpor', 'wqor', 'wror', 'wsor', 'wtor', 'wuor', 'wvor', 'wwor', 'wxor', 'wyor', 'wzor',
			'woar', 'wobr', 'wocr', 'wodr', 'woer', 'wofr', 'wogr', 'wohr', 'woir', 'wojr', 'wokr', 'wolr', 'womr', 'wonr', 'woor', 'wopr', 'woqr', 'worr', 'wosr', 'wotr', 'wour', 'wovr', 'wowr', 'woxr', 'woyr', 'wozr',
			'wora', 'worb', 'worc', 'word', 'wore', 'worf', 'worg', 'worh', 'wori', 'worj', 'work', 'worl', 'worm', 'worn', 'woro', 'worp', 'worq', 'worr', 'wors', 'wort', 'woru', 'worv', 'worw', 'worx', 'wory', 'worz']
		
	end

end

describe LanguageModelBuilder do
	before(:each) do
		@model = LanguageModelBuilder.new
	end

	context "when building from string" do

		it "should build a one word model" do
			@model.build "foo"

			@model["foo"].should == 1
		end

		it "should build two word model" do
			@model.build "foo bar"

			@model["foo"].should == 1
			@model["bar"].should == 1
		end

		it "should build model with repeat words" do
			@model.build "foo foo"

			@model["foo"].should == 2
		end

		it "should ignore periods" do
			@model.build "foo. foo"

			@model["foo"].should == 2
		end

		it "should ignore commas" do
			@model.build "foo, foo"

			@model["foo"].should == 2
		end

		it "should ignore semicolons" do
			@model.build "foo; foo"

			@model["foo"].should == 2
		end

		it "should ignore quotes" do
			@model.build '"foo" foo'

			@model["foo"].should == 2
		end
	end


	it "should build a model from the filesystem" do
		@model.build_from_filesystem(PROJECT_DIR + "/small.txt")
		
		@model["had"].should == 20
		@model["eyes"].should == 8
	end

end
