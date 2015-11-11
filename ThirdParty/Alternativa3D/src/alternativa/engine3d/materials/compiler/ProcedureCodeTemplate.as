package alternativa.engine3d.materials.compiler {
import flash.display3D.Context3DTextureFormat;

public class ProcedureCodeTemplate {
	private const parser:RegExp = /\$tex.+(<(.*)>)/;

	private var _templateInstructions:Array;
	private var _substitutionIndices:Vector.<int>;
	private var _substitutionParams:Vector.<String>;

	public function ProcedureCodeTemplate(instructions:Array) {
		_substitutionIndices = new <int>[];
		_substitutionParams = new <String>[];
		for (var i:int = 0; i < instructions.length; ++i) {
			var matchData:Array = parser.exec(instructions[i]);
			if (matchData != null) {
				var texOptions:Array = matchData[2].split(',');
				var cleanedOptions:Vector.<String> = new <String>[];
				for (var j:int = 0; j < texOptions.length; ++j) {
					texOptions[j] = texOptions[j].replace(' ', '');
					if (texOptions[j].substr(0, 3) != "dxt") {
						cleanedOptions.push(texOptions[j]);
					}
				}
				_substitutionIndices.push(i);
				_substitutionParams.push(cleanedOptions.join());
				instructions[i] = instructions[i].substr(1, instructions[i].length - matchData[1].length - 1);
			}
		}
		_templateInstructions = instructions;
	}

	public function substitute(textureModes:Vector.<String>):Array
	{
		var output:Array = _templateInstructions.concat();

		var substitution:String;
		for (var i:int = 0; i < _substitutionIndices.length; ++i) {
			substitution = "";
			if (textureModes[i] == Context3DTextureFormat.COMPRESSED_ALPHA) {
				substitution = ",dxt5";
			} else if (textureModes[i] == Context3DTextureFormat.COMPRESSED) {
				substitution = ",dxt1";
			}
			output[_substitutionIndices[i]] = String(output[_substitutionIndices[i]]) + "<" + _substitutionParams[i] + substitution + ">";
		}

		return output;
	}
}
}
