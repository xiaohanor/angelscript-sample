enum EDoppelgangerMimicState
{
	FullMimic,
	WantsFullMimic,
	MimicAppearance,
	RandomMove,
	Reveal
}

class USanctuaryDoppelgangerComponent : UActorComponent
{
	UPROPERTY()
	UMaterialInterface CreepyEyesMaterial;

	AHazePlayerCharacter MimicTarget;
	FTransform MimicTargetInverseTransform;
	FTransform MimicTransform;
	FTransform DoppelTransform;

	EDoppelgangerMimicState MimicState;
	float StartCreepyTime;

	USkeletalMesh TrueForm;
	TArray<UMaterialInterface> TrueMaterials;

	FVector GetMimicLocation()
	{
		return (MimicTargetInverseTransform * MimicTransform).TransformPosition(MimicTarget.ActorLocation); 
	}
}
