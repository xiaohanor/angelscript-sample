class ACentipedeAllowStretchVolume : AVolume
{
	default BrushColor = FLinearColor(0.18, 0.00, 1.00);
	default BrushComponent.LineThickness = 10;
	default RootComponent.Mobility = EComponentMobility::Movable;
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");

	UPROPERTY(EditInstanceOnly)
	bool bSwingStretchVolume = false;

	UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;
		UPlayerCentipedeComponent CentipedeComponent = UPlayerCentipedeComponent::Get(Player);
		if (CentipedeComponent == nullptr)
            return;
		CentipedeComponent.AllowStretchDeathVolumes.AddUnique(this);
    }

	
	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;
		UPlayerCentipedeComponent CentipedeComponent = UPlayerCentipedeComponent::Get(Player);
		if (CentipedeComponent == nullptr)
            return;
		if (!CentipedeComponent.AllowStretchDeathVolumes.Contains(this))
            return;
		CentipedeComponent.AllowStretchDeathVolumes.Remove(this);
	}
};