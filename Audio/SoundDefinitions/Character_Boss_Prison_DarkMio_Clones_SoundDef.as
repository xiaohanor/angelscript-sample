
UCLASS(Abstract)
class UCharacter_Boss_Prison_DarkMio_Clones_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void CloneAttack(FPrisonBossCloneAttackEventData Data){}

	UFUNCTION(BlueprintEvent)
	void CloneFinalAttackTelegraph(){}

	/* END OF AUTO-GENERATED CODE */

	APrisonBoss DarkMio;
	UPrisonBossCloneManagerComponent CloneManagerComp;

	UPROPERTY(BlueprintReadWrite)
	FHazeAudioEmitterRotationPool CloneAttackEmitterPool;	

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		DarkMio = Cast<APrisonBoss>(HazeOwner);
		CloneManagerComp = UPrisonBossCloneManagerComponent::Get(DarkMio);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return DarkMio.CurrentAttackType == EPrisonBossAttackType::Clone;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return DarkMio.CurrentAttackType != EPrisonBossAttackType::Clone;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DefaultEmitter.SetEmitterLocation(DarkMio.ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(DarkMio.AnimationData.bIsDuplicatingClone)
		{
			if(!CloneManagerComp.Clones.IsEmpty())
			{
				const FVector LatestClonePosition = CloneManagerComp.Clones.Last().ActorLocation;			
				const FVector LerpedCloneSpawnEmitterLocation = Math::VInterpConstantTo(DefaultEmitter.GetEmitterLocation(), LatestClonePosition, DeltaSeconds, 5000.f);

				DefaultEmitter.SetEmitterLocation(LerpedCloneSpawnEmitterLocation, true);
			}
		}
	}
}