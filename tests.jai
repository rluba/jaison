// Some tests to make sure we don’t leak stuff, even in complex scenarios.

#import "Basic"()(MEMORY_DEBUGGER = true);
#load "module.jai";

JSON :: #string END
{
	"errors": true,
	"items": [
		{
			"index": {
				"_id": "somesensitiveid",
				"_index": "documents",
				"_primary_term": 1,
				"_seq_no": 35230,
				"_shards": {
					"failed": 0,
					"successful": 1,
					"total": 2
				},
				"_type": "_doc",
				"_version": 1,
				"result": "created",
				"status": 201
			}
		},
		{
			"index": {
				"_id": "somesensitiveid2",
				"_index": "documents",
				"_type": "_doc",
				"error": {
					"caused_by": {
						"reason": "Invalid UTF-8 middle byte 0x6e\n at [Source: (org.elasticsearch.common.bytes.AbstractBytesReference$MarkSupportingStreamInputWrapper); line: 1, column: 119]",
						"type": "json_parse_exception"
					},
					"reason": "failed to parse field [path] of type [text] in document with id 'somesensitiveid2'. Preview of field's value: ''",
					"type": "mapper_parsing_exception"
				},
				"status": 400
			}
		}
	],
	"took": 200
}
END

JSON2 :: #string END
{"took":200,"errors":true,"items":[{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35230,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35231,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35232,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35233,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35234,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35235,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35236,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35237,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35238,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35239,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35240,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35241,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35242,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35243,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35244,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35245,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35246,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35247,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35248,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35249,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35250,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35251,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35252,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35253,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35254,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35255,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35256,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35257,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35258,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35259,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35260,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35261,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35262,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35263,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35264,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35265,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35266,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35267,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35268,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35269,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35270,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35271,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35272,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35273,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35274,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35275,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35276,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35277,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35278,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35279,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35280,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35281,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35282,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35283,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35284,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35285,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35286,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35287,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35288,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35289,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35290,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35291,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35292,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35293,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35294,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35295,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35296,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35297,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35298,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35299,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35300,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35301,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","status":400,"error":{"type":"mapper_parsing_exception","reason":"failed to parse field [path] of type [text] in document with id '_daten_akten_m_30500-30999_m30540_m30540-GT_files_OFA_-_Brand_registration_Advertisements_DE_June_Elektroh_ndler_SV_4720_pdf'. Preview of field's value: ''","caused_by":{"type":"json_parse_exception","reason":"Invalid UTF-8 middle byte 0x6e\n at [Source: (org.elasticsearch.common.bytes.AbstractBytesReference$MarkSupportingStreamInputWrapper); line: 1, column: 119]"}}}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35302,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35303,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35304,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35305,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35306,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35307,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35308,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35309,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35310,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35311,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35312,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35313,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35314,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35315,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35316,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35317,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35318,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35319,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35320,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35321,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35322,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35323,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35324,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35325,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35326,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35327,"_primary_term":1,"status":201}},{"index":{"_index":"documents","_type":"_doc","_id":"somesensitiveid","_version":1,"result":"created","_shards":{"total":2,"successful":1,"failed":0},"_seq_no":35328,"_primary_term":1,"status":201}}]}
END

Message :: struct {
	message: string;
}

MESSAGE_JSON :: #string END
{
	"message" : "hello sailor"
}
END

Index_Result :: struct {
	took: int;
	errors: bool;
	items: [..] Item;
	Item :: struct {
		index: Index;
	}
	Index :: struct {
		_id: string;
		_index: string;
		_type: string;
		_version: int;
		_shards: Shard_Info;
		_seq_no: int;
		_primary_term: int;
		result: string;
		status: int;
		error: Error;
	}
	Error :: struct {
		caused_by: *Error;
		reason: string;
		type: string;
	}
	Shard_Info :: struct {
		total: int;
		successful: int;
		failed: int;
	}
}

free_result :: (result: Index_Result) {
	for result.items	{
        free_error(it.index.error);
        free(it.index._id);
        free(it.index._index);
        free(it.index._type);
        free(it.index.result);
    }
	array_free(result.items);
}

free_error :: (error: Index_Result.Error) {
    if error.caused_by {
        free_error(error.caused_by);
        free(error.caused_by);
    }
    free(error.reason);
    free(error.type);
}

main :: () {
	{
		success, result := json_parse_string(JSON, Index_Result);
		defer free_result(result);
		log("Success: % result: %\n", success, result);
	}
	{
		success, result := json_parse_string(JSON2, Index_Result);
		defer free_result(result);
		log("Success: % result: %\n", success, result);
	}

    log("Report 1:");
    report_memory_leaks();

	for 0..200000 {
		success, result := json_parse_string(JSON);
		defer json_free(result);
		assert(success, "Parse % failed", it);
        reset_temporary_storage();
	}

    log("Report 2:");
    report_memory_leaks();


	for 0..100 {
		success, result := json_parse_string(MESSAGE_JSON, Message);
		defer free(result.message);
		assert(success, "Parse % failed", it);
        reset_temporary_storage();
	}

    log("Report 3:");
    report_memory_leaks();
}
