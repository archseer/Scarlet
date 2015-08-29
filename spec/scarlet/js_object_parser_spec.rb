require 'spec_helper'
require 'scarlet/js_object_parser'

describe Scarlet::JsObjectParser do
  context '.parse' do
    it 'parses a valid js object string' do
      result = Scarlet::JsObjectParser.parse('[,,,,1,2,2.0,true,false,null,[],[,,,"eggo", 1,2,3,[]],[1,2,3],"string",{a:1}]')

      expect(result).to eq(
        [nil, nil, nil, nil, 1, 2, 2.0, true, false, nil,
          [],
          [nil, nil, nil, "eggo", 1, 2, 3, []],
          [1, 2, 3],
          "string",
          { "a" => 1 }
        ]
      )
    end
  end
end
