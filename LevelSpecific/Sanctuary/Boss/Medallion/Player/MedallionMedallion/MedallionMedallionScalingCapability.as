class UMedallionMedallionScalingCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	AMedallionMedallionActor Medallion;
	AHazePlayerCharacter Player;

	const float CutsceneScale = 1.0;
	const float GameplayScale = 1.5;
	FHazeAcceleratedFloat AccScale;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Medallion = Cast<AMedallionMedallionActor>(Owner);
		Player = Game::GetPlayer(Medallion.TargetPlayer);
		AccScale.SnapTo(Medallion.GetActorScale3D().Size());
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return false; // by Hannes design
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.bIsControlledByCutscene)
			AccScale.AccelerateTo(CutsceneScale, 0.5, DeltaTime);
		else
			AccScale.AccelerateTo(GameplayScale, 0.5, DeltaTime);
		Medallion.SetActorScale3D(FVector::OneVector * AccScale.Value);
	}
};