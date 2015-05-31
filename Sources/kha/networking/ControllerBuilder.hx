package kha.networking;

import haxe.macro.Context;
import haxe.macro.Expr.Field;

class ControllerBuilder {
	macro static public function build(): Array<Field> {
		var fields = Context.getBuildFields();
		
		#if js
		#if !node
		{
			var funcindex = 0;
			for (field in fields) {
				var input = false;
				for (meta in field.meta) {
					if (meta.name == "input") {
						input = true;
						break;
					}
				}
				if (!input) continue;
				
				switch (field.kind) {
				case FFun(f):
					var size = 17;
					for (arg in f.args) {
						switch (arg.type) {
						case TPath(p):
							switch (p.name) {
							case "Int":
								size += 4;
							case "String":
								size += 1;
							case "Float":
								size += 8;
							case "Bool":
								size += 1;
							case "Key":
								size += 1;
							}
						default:
						}
					}
					
					var expr = macro @:mergeBlock {
						var bytes = haxe.io.Bytes.alloc($v { size } );
						bytes.set(0, kha.networking.Session.CONTROLLER_UPDATES);
						bytes.setInt32(1, _id());
						bytes.setDouble(5, Scheduler.realTime());
						bytes.setInt32(13, $v { funcindex } );
					};
					var index: Int = 17;
					for (arg in f.args) {
						switch (arg.type) {
						case TPath(p):
							switch (p.name) {
							case "Int":
								var argname = arg.name;
								expr = macro @:mergeBlock {
									$expr;
									bytes.setInt32($v { index }, $i { argname });
								};
								index += 4;
							case "String":
								var argname = arg.name;
								expr = macro @:mergeBlock {
									$expr;
									bytes.set($v { index }, $i { argname }.charCodeAt(0));
								};
								index += 1;
							case "Float":
								var argname = arg.name;
								expr = macro @:mergeBlock {
									$expr;
									bytes.setDouble($v { index }, $i { argname } );
								};
								index += 8;
							case "Bool":
								var argname = arg.name;
								expr = macro @:mergeBlock {
									$expr;
									bytes.set($v { index } , $i { argname } ? 1 : 0);
								};
								index += 1;
							case "Key":
								var argname = arg.name;
								expr = macro @:mergeBlock {
									$expr;
									bytes.set($v { index } , Type.enumIndex($i { argname } ));
								};
								index += 1;
							}
						default:
						}
					}
					var original = f.expr;
					expr = macro {
						$expr;
						kha.networking.Session.the().network.send(bytes, false);
						$original;
					};
					f.expr = expr;
				default:
				}
				++funcindex;
			}
		}
		#end
		
		var receive = macro @:mergeBlock {
			var funcindex = bytes.getInt32(offset + 0);
		};
		{
			var funcindex = 0;
			for (field in fields) {
				var input = false;
				for (meta in field.meta) {
					if (meta.name == "input") {
						input = true;
						break;
					}
				}
				if (!input) continue;
				
				switch (field.kind) {
				case FFun(f):
					var expr = macro { };
					var index: Int = 4;
					var varindex: Int = 0;
					for (arg in f.args) {
						switch (arg.type) {
						case TPath(p):
							switch (p.name) {
							case "Int":
								var argname = arg.name;
								var varname = "input" + varindex;
								expr = macro @:mergeBlock {
									$expr;
									var $varname: Int = bytes.getInt32(offset + $v { index } );
								};
								index += 4;
							case "String":
								var argname = arg.name;
								var varname = "input" + varindex;
								expr = macro @:mergeBlock {
									$expr;
									var $varname: String = String.fromCharCode(bytes.get(offset + $v { index } ));
								};
								index += 1;
							case "Float":
								var argname = arg.name;
								var varname = "input" + varindex;
								expr = macro @:mergeBlock {
									$expr;
									var $varname: Float = bytes.getDouble(offset + $v { index } );
								};
								index += 8;
							case "Bool":
								var argname = arg.name;
								var varname = "input" + varindex;
								expr = macro @:mergeBlock {
									$expr;
									var $varname: Bool = bytes.get(offset + $v { index } ) != 0;
								};
								index += 1;
							case "Key":
								var argname = arg.name;
								var varname = "input" + varindex;
								expr = macro @:mergeBlock {
									$expr;
									var $varname: kha.Key = kha.Key.createByIndex(bytes.get(offset + $v { index } ));
								};
								index += 1;
							}
						default:
						}
						++varindex;
					}
					switch (varindex) {
					case 1:
						var funcname = field.name;
						receive = macro @:mergeBlock {
							$receive;
							if (funcindex == $v { funcindex } ) {
								$expr;
								$i { funcname } (input0);
								return;
							}
						};
					case 2:
						var funcname = field.name;
						receive = macro @:mergeBlock {
							$receive;
							if (funcindex == $v { funcindex } ) {
								$expr;
								$i { funcname }(input0, input1);
								return;
							}
						};
					case 3:
						var funcname = field.name;
						receive = macro @:mergeBlock {
							$receive;
							if (funcindex == $v { funcindex } ) {
								$expr;
								$i { funcname }(input0, input1, input2);
								return;
							}
						};
					}
				default:
				}
				++funcindex;
			}
		}
		
		fields.push({
			name: "_receive",
			doc: null,
			meta: [],
			access: [APublic],
			kind: FFun({
				ret: null,
				params: null,
				expr: receive,
				args: [{
					value: null,
					type: Context.toComplexType(Context.getType("Int")),
					opt: null,
					name: "offset" },
					{
					value: null,
					type: Context.toComplexType(Context.getType("haxe.io.Bytes")),
					opt: null,
					name: "bytes"}]
			}),
			pos: Context.currentPos()
		});
		
		fields.push({
			name: "_id",
			doc: null,
			meta: [],
			access: [APublic],
			kind: FFun({
				ret: Context.toComplexType(Context.getType("Int")),
				params: null,
				expr: macro { return __id; },
				args: []
			}),
			pos: Context.currentPos()
		});
		
		fields.push({
			name: "__id",
			doc: null,
			meta: [],
			access: [APrivate],
			kind: FVar(macro: Int, macro 0),
			pos: Context.currentPos()
		});
		#end
		
		return fields;
	}
}
