
UCLASS(Abstract)
class UGameplay_Character_Creature_Player_Dragon_Baby_TailDragon_Vocalizations_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnTailReleased(FBabyDragonTailClimbFreeFormOnTailReleasedParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnTailAttached(FBabyDragonTailClimbFreeFormOnTailAttachedParams Params){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PlayerOwner.IsPlayerDeadOrRespawning())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PlayerOwner.IsPlayerDeadOrRespawning())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		SetPlayerOwner(Game::GetZoe());

		ABabyDragon Dragon = Cast<ABabyDragon>(HazeOwner);

		auto PlayerAudioMoveComp = UPlayerMovementAudioComponent::Get(PlayerOwner);
		PlayerAudioMoveComp.LinkMovementRequests(Dragon.MoveAudioComp);
	}
}