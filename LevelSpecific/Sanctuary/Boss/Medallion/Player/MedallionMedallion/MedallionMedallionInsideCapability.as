class UMedallionMedallionInsideCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	AMedallionMedallionActor Medallion;
	AHazePlayerCharacter Player;
	UMedallionPlayerComponent MedallionComp;
	const float CloseDistance = 10000.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Medallion = Cast<AMedallionMedallionActor>(Owner);
		Player = Game::GetPlayer(Medallion.TargetPlayer);
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Medallion.MedallionState != EMedallionMedallionState::HoverTowardsInsideDummy)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Medallion.MedallionState != EMedallionMedallionState::HoverTowardsInsideDummy)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Medallion.AttachToComponent(Player.Mesh, Medallion.ChestAttachSocket, EAttachmentRule::SnapToTarget);
		Medallion.CinematicSkelMeshBase.ResetAllAnimation(true);
		Medallion.VisibleInstigators.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Medallion.VisibleInstigators.Remove(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TowardsOther = MedallionComp.InsideZoeFakeMedallion.ActorLocation - Medallion.ActorLocation;
		TowardsOther.Z = 0.0;
		TowardsOther = TowardsOther.GetSafeNormal();

		FVector MedallionLocation = Medallion.ActorLocation + TowardsOther * 50.0;
		Medallion.RemoveOffsetsBetweenStatesRoot.SetWorldRotation(TowardsOther.ToOrientationRotator());
		Medallion.RemoveOffsetsBetweenStatesRoot.SetWorldLocation(MedallionLocation);
		
		//Debug::DrawDebugString(Medallion.MedallionRoot.WorldLocation, "MEDALLION", ColorDebug::Rainbow(2.0));
	}
};