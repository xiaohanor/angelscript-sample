
UCLASS(Abstract)
class UGameplay_Character_Boss_Island_Walker_Platform_Launch_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void Launched(){}

	/* END OF AUTO-GENERATED CODE */

	AIslandOverloadJumpPad JumpPad;

	UPROPERTY(BlueprintReadOnly)
	TArray<AHazePlayerCharacter> PlayersOnLaunchPad;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		JumpPad = Cast<AIslandOverloadJumpPad>(HazeOwner);		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		auto Walker = TListedActors<AAIIslandWalker>().GetSingle();
		if(Walker == nullptr)
			return false;

		if(Walker.PhaseComp.Phase >= EIslandWalkerPhase::Suspended
		&& Walker.PhaseComp.Phase < EIslandWalkerPhase::Decapitated)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		auto Walker = TListedActors<AAIIslandWalker>().GetSingle();
		if(Walker == nullptr)
			return true;

		if(Walker.PhaseComp.Phase >= EIslandWalkerPhase::Suspended
		&& Walker.PhaseComp.Phase < EIslandWalkerPhase::Decapitated)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		JumpPad.PlayerEnterBox.OnComponentBeginOverlap.AddUFunction(this, n"OnPlayerEnter");
		JumpPad.PlayerEnterBox.OnComponentEndOverlap.AddUFunction(this, n"OnPlayerExit");
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerEnter(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in HitResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		PlayersOnLaunchPad.Add(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerExit(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		PlayersOnLaunchPad.RemoveSingleSwap(Player);
	}
}