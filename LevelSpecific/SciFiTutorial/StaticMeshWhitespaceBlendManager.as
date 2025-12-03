UCLASS()
class AStaticMeshWhitespaceBlendManager : AHazeActor
{
	UFUNCTION(CallInEditor)
	void FixBlendTimings()
	{
		auto AllBlendObjects = TListedActors<AStaticMeshWhitespaceBlend>().GetArray();
		
		for (int i = 0; i < AllBlendObjects.Num(); i++)
		{
			if(AllBlendObjects[i] == nullptr)
				continue;
			
			AllBlendObjects[i].FixBlendTimings();
			AllBlendObjects[i].Init();
		}
		
	}

	UFUNCTION(BlueprintOverride)
	void OnSequencerEvaluation(FHazeSequencerEvalParams EvaluationParams)
	{
		for (AStaticMeshWhitespaceBlend BlendObject : TListedActors<AStaticMeshWhitespaceBlend>())
		{
			if(!IsValid(BlendObject))
				continue;

			// Only do this one single time in game world, since the values won't change
			if (!BlendObject.bBlendTimingsFixed || !GetWorld().IsGameWorld())
			{
				BlendObject.FixBlendTimings();
				BlendObject.bBlendTimingsFixed = true;
			}

			BlendObject.OnSequenceUpdate(EvaluationParams.TimeFromSectionStart);
		}
	}
}
