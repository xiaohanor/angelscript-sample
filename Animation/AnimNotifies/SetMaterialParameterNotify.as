struct FNotifierScalarParameter
{
	UPROPERTY(EditAnywhere)
	FName Name;

	UPROPERTY(EditAnywhere)
	float Value;
}
struct FNotifierVectorParameter
{
	UPROPERTY(EditAnywhere)
	FName Name;

	UPROPERTY(EditAnywhere)
	FLinearColor Value;
}
struct FNotifierTextureParameter
{
	UPROPERTY(EditAnywhere)
	FName Name;

	UPROPERTY(EditAnywhere)
	UTexture2D Value;
}

struct FNotifierScalarParameterCurve
{
	UPROPERTY(EditAnywhere)
	FName Name;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Value;
}
struct FNotifierColorParameterCurve
{
	UPROPERTY(EditAnywhere)
	FName Name;

	UPROPERTY(EditAnywhere)
	FRuntimeCurveLinearColor Value;
}

void MakeMaterialsDynamic(USkeletalMeshComponent MeshComp, int Index, bool AllMaterials)
{
	if(AllMaterials)
	{
		for(int i = 0; i < MeshComp.Materials.Num(); i++)
		{
			MeshComp.CreateDynamicMaterialInstance(i);
		}
	}
	else
	{
		MeshComp.CreateDynamicMaterialInstance(Index);
	}
}

TArray<int> GetMaterialIndicesToChange(USkeletalMeshComponent MeshComp, int Index, bool AllMaterials)
{
	TArray<int> Result;
	
	if(AllMaterials)
	{
		for(int i = 0; i < MeshComp.Materials.Num(); i++)
		{
			Result.Add(i);
		}
	}
	else
	{
		Result.Add(Index);
	}
	return Result;
}

// If this ends up not being nice, adding a TMap of UAnimNotifyStates and floats for current time in HazeSkeletalMeshComponent (ask jonas)
UCLASS(NotBlueprintable, meta = ("SetMaterialParameterCurve"))
class UAnimNotify_SetMaterialParameterCurve : UAnimNotifyState 
{
	UPROPERTY(EditAnywhere)	
	bool AllMaterials;

	UPROPERTY(EditAnywhere)
	int MaterialIndex;

	UPROPERTY(EditAnywhere)
	TArray<FNotifierScalarParameterCurve> ScalarParameters;

	//UPROPERTY(EditAnywhere)
	//TArray<FNotifierColorParameterCurve> ColorParameters;

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		MakeMaterialsDynamic(MeshComp, MaterialIndex, AllMaterials);
		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	bool NotifyTick(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float FrameDeltaTime, FAnimNotifyEventReference EventReference) const
	{

		float NormalizedTime = 0;
		TArray<FHazePlayingAnimationData> OutAnimations;
		MeshComp.GetCurrentlyPlayingAnimations(OutAnimations);
		for (int i = 0; i < OutAnimations.Num(); i++)
		{
			float Start = OutAnimations[i].Sequence.GetAnimNotifyStateStartTime(UAnimNotify_SetMaterialParameterCurve);
			float End = OutAnimations[i].Sequence.GetAnimNotifyStateEndTime(UAnimNotify_SetMaterialParameterCurve);
			
			NormalizedTime = (OutAnimations[i].CurrentPosition - Start) / (End - Start);
		}
		
		TArray<int> MaterialsToChange = GetMaterialIndicesToChange(MeshComp, MaterialIndex, AllMaterials);
		for(int i = 0; i < MaterialsToChange.Num(); i++)
		{
			UMaterialInstanceDynamic Mat = Cast<UMaterialInstanceDynamic>(MeshComp.Materials[MaterialsToChange[i]]);
			if(Mat == nullptr)
				continue;

			for(int j = 0; j < ScalarParameters.Num(); j++)
			{
				Mat.SetScalarParameterValue(ScalarParameters[j].Name, ScalarParameters[j].Value.GetFloatValue(NormalizedTime));
			}

			//for(int j = 0; j < ColorParameters.Num(); j++)
			//{
			//	Mat.SetVectorParameterValue(ColorParameters[j].Name, ColorParameters[j].Value.GetLinearColorValue(NormalizedTime));
			//}
		}
		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		return true;
	}

}
UCLASS(NotBlueprintable, meta = ("SetMaterialParameter"))
class UAnimNotify_SetMaterialParameter : UAnimNotify 
{
	UPROPERTY(EditAnywhere)
	bool AllMaterials;

	UPROPERTY(EditAnywhere)
	int MaterialIndex;

	UPROPERTY(EditAnywhere)
	TArray<FNotifierScalarParameter> ScalarParameters;

	UPROPERTY(EditAnywhere)
	TArray<FNotifierVectorParameter> VectorParameters;

	UPROPERTY(EditAnywhere)
	TArray<FNotifierTextureParameter> TextureParameters;

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		MakeMaterialsDynamic(MeshComp, MaterialIndex, AllMaterials);

		TArray<int>  MaterialsToChange = GetMaterialIndicesToChange(MeshComp, MaterialIndex, AllMaterials);

		for(int i = 0; i < MaterialsToChange.Num(); i++)
		{
			UMaterialInstanceDynamic Mat = Cast<UMaterialInstanceDynamic>(MeshComp.Materials[MaterialsToChange[i]]);

			if(Mat == nullptr)
				continue;

			for(int j = 0; j < ScalarParameters.Num(); j++)
			{
				Mat.SetScalarParameterValue(ScalarParameters[j].Name, ScalarParameters[j].Value);
			}

			for(int j = 0; j < VectorParameters.Num(); j++)
			{
				Mat.SetVectorParameterValue(VectorParameters[j].Name, VectorParameters[j].Value);
			}

			for(int j = 0; j < TextureParameters.Num(); j++)
			{
				Mat.SetTextureParameterValue(TextureParameters[j].Name, TextureParameters[j].Value);
			}
		}
		return true;
	}
};