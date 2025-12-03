class UMoonMarketCatSoulToGateCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	AMoonMarketCat Cat;
	FHazeAcceleratedVector AccelVector;
	FHazeAcceleratedRotator AccelRot;
	FHazeAcceleratedVector AccelScale;
	FVector OriginalScale;

	FHazeAcceleratedFloat AccelFloatOpacity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Cat = Cast<AMoonMarketCat>(Owner);
		AccelFloatOpacity.SnapTo(Cast<UMaterialInstanceConstant>(Cat.SkelMeshComp.GetMaterial(0)).GetScalarParameterValue(n"Opacity")); 
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Cat.bHasbeenCompleted)
			return false;
		
		if (!Cat.bFlyToCatHead)
			return false;

		if (Cat.bCutsceneCat)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if ((Cat.ActorLocation - Cat.CatHead.ActorLocation).Size() < 35.0)
			return true;

		if(ActiveDuration > 3)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccelVector.SnapTo(Cat.ActorLocation);
		AccelRot.SnapTo(Cat.ActorRotation);
		AccelScale.SnapTo(Cat.ActorScale3D);
		OriginalScale = Cat.ActorScale3D;
		Cat.SoulCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Cat.DeliverCatSoul();
		Cat.AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Direction = (Cat.ActorLocation - Cat.CatHead.CatTargetComp.WorldLocation).GetSafeNormal();
		AccelVector.AccelerateTo(Cat.CatHead.CatTargetComp.WorldLocation, 2.5, DeltaTime);
		AccelFloatOpacity.AccelerateTo(0.0, 2.5, DeltaTime);
		AccelRot.AccelerateTo(Direction.Rotation(), 2.5, DeltaTime);
		AccelScale.AccelerateTo(OriginalScale * 0.75, 1.5, DeltaTime);
		Cat.ActorLocation = AccelVector.Value;
		Cat.ActorRotation = AccelRot.Value;
		Cat.ActorScale3D = AccelScale.Value;
		Cat.SkelMeshComp.SetScalarParameterValueOnMaterials(n"Opacity", AccelFloatOpacity.Value);
	}
};