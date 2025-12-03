
UCLASS(Abstract)
class UCharacter_Boss_Prison_DarkMio_Donut_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void DonutSpawnAttack(){}

	/* END OF AUTO-GENERATED CODE */

	APrisonBoss DarkMio;

	UPROPERTY(NotVisible)
	UHazeAudioEmitter DonutMultiEmitter;

	TArray<FAkSoundPosition> DonutSoundPositions;
	default DonutSoundPositions.SetNum(2);

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		DarkMio = Cast<APrisonBoss>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = DarkMio;
		
		if(EmitterName == n"DonutMultiEmitter")
			bUseAttach = false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return DarkMio.CurrentAttackType == EPrisonBossAttackType::Donut;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return DarkMio.CurrentAttackType != EPrisonBossAttackType::Donut;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Re-use DarkMio.AnimationData.bSpawningDonut to check if it has started before sounddef is activated.
		if (bFirstActivation && DarkMio.AnimationData.bSpawningDonut)
		{
			DonutSpawnAttack();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		auto ActiveDonuts = TListedActors<APrisonBossDonutAttack>().GetArray();
		if(ActiveDonuts.IsEmpty())
			return;

		APrisonBossDonutAttack CurrentDonut = ActiveDonuts.Last();

		for(auto Player : Game::GetPlayers())
		{
			const FVector PlayerLocation = Player.ActorLocation;

			const FVector ProjectedPlayerLocation = CurrentDonut.ActorTransform.InverseTransformPosition(PlayerLocation);
			const FVector ProjectedPlayerLocationOnDonutEdge = ProjectedPlayerLocation.GetSafeNormal() * CurrentDonut.CurrentRadius;
			const FVector PlayerWorldLocationOnEdge = CurrentDonut.ActorTransform.TransformPosition(ProjectedPlayerLocationOnDonutEdge);

			DonutSoundPositions[int(Player.Player)].SetPosition(PlayerWorldLocationOnEdge);
		}

		DonutMultiEmitter.SetMultiplePositions(DonutSoundPositions);
	}
}