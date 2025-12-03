
UCLASS(Abstract)
class UGameplay_Gadget_Player_DragonSword_Mio_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnHitEnemy(FDragonSwordHitData HitData){}

	UFUNCTION(BlueprintEvent)
	void StopHitWindow(){}

	UFUNCTION(BlueprintEvent)
	void StartHitWindow(){}

	UFUNCTION(BlueprintEvent)
	void StopAttackSequence(){}

	UFUNCTION(BlueprintEvent)
	void StartAttackAnimation(FDragonSwordCombatStartAttackAnimationEventData EventData){}

	UFUNCTION(BlueprintEvent)
	void StartAttackSequence(){}

	UFUNCTION(BlueprintEvent)
	void StopRush(){}

	UFUNCTION(BlueprintEvent)
	void StartRush(FDragonSwordCombatStartRushEventData EventData){}

	/* END OF AUTO-GENERATED CODE */

	ADragonSword Sword;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Sword = Cast<ADragonSword>(HazeOwner);

		auto Player = Game::GetMio();
		UPlayerMovementAudioComponent PlayerMoveAudioComp = UPlayerMovementAudioComponent::Get(Player);
		PlayerMoveAudioComp.LinkMovementRequests(Sword.MoveAudioComp);
	}

}