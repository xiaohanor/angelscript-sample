class ASanctuaryHydraKillerBallistaProjectileSequencer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(Interp,EditAnywhere)
	float Width = 150;
	UPROPERTY(Interp,EditAnywhere)
	float Height = 1;
	UPROPERTY(Interp,EditAnywhere)
	float Depth = 1000;
	
	UPROPERTY(Interp,EditAnywhere)
	AHazeActor MedallionTargetHydra0;

	UPROPERTY(Interp,EditAnywhere)
	AHazeActor MedallionTargetHydra1;

	UFUNCTION(BlueprintOverride)
	void OnSequencerEvaluation(FHazeSequencerEvalParams EvalParams)
	{
		CutHydraUpdate();
	}

	UFUNCTION()
	private void CutHydraUpdate()
	{
		if (MedallionTargetHydra0 != nullptr)
		{
			UHazeSkeletalMeshComponentBase MeshComp = MedallionTargetHydra0.GetComponentByClass(UHazeSkeletalMeshComponentBase);
			if (MeshComp != nullptr)
			{
				MeshComp.SetVectorParameterValueOnMaterials(n"ArrowLocation", GetActorLocation());
				MeshComp.SetVectorParameterValueOnMaterials(n"ArrowForwardDirection", GetActorForwardVector());
				MeshComp.SetVectorParameterValueOnMaterials(n"ArrowUpDirection", GetActorUpVector());

				MeshComp.SetScalarParameterValueOnMaterials(n"ArrowGradientWidth", Width);
				MeshComp.SetScalarParameterValueOnMaterials(n"ArrowGradientHeight", Height);
				MeshComp.SetScalarParameterValueOnMaterials(n"ArrowPushStrength", Depth);
			}
		}

		if (MedallionTargetHydra1 != nullptr)
		{
			UHazeSkeletalMeshComponentBase MeshComp = MedallionTargetHydra1.GetComponentByClass(UHazeSkeletalMeshComponentBase);
			if (MeshComp != nullptr)
			{
				MeshComp.SetVectorParameterValueOnMaterials(n"ArrowLocation", GetActorLocation());
				MeshComp.SetVectorParameterValueOnMaterials(n"ArrowForwardDirection", GetActorForwardVector());
				MeshComp.SetVectorParameterValueOnMaterials(n"ArrowUpDirection", GetActorUpVector());

				MeshComp.SetScalarParameterValueOnMaterials(n"ArrowGradientWidth", Width);
				MeshComp.SetScalarParameterValueOnMaterials(n"ArrowGradientHeight", Height);
				MeshComp.SetScalarParameterValueOnMaterials(n"ArrowPushStrength", Depth);
			}
		}
	}
};