
UCLASS(Abstract)
class UCharacter_Boss_Prison_DarkMio_ZigZag_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	APrisonBoss DarkMio;

	UPROPERTY(NotVisible)
	UHazeAudioEmitter ZigZagMultiEmitter;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		DarkMio = Cast<APrisonBoss>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return DarkMio.CurrentAttackType == EPrisonBossAttackType::ZigZag;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return DarkMio.CurrentAttackType != EPrisonBossAttackType::ZigZag;
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;

		if(EmitterName == n"ZigZagMultiEmitter")
			bUseAttach = false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		TArray<APrisonBossZigZagAttack> ZigZags = TListedActors<APrisonBossZigZagAttack>().GetArray();
		const int ZigZagCount = ZigZags.Num();
		if(ZigZagCount == 0)
			return;

		TArray<FAkSoundPosition> ZigZagSoundPositions;
		ZigZagSoundPositions.SetNum(ZigZagCount);

		const FVector ZoeLocation = Game::GetZoe().ActorLocation;
		for(int i = 0; i < ZigZagCount; ++i)
		{
			APrisonBossZigZagAttack ZigZag = ZigZags[i];

			const FVector SplineEnd = ZigZag.RuntimeSpline.GetLocationAtDistance(ZigZag.Dist);			
			const FVector SplineStart = ZigZag.RuntimeSpline.GetLocationAtDistance(ZigZag.Dist - 100);
	
			FHazeRuntimeSpline PartialSpline;	
			PartialSpline.AddPoint(SplineStart);
			PartialSpline.AddPoint(SplineEnd);
			PartialSpline.SetCustomCurvature(0.5);

			const FVector ClosestZoePos = PartialSpline.GetClosestLocationToLocation(ZoeLocation);
			ZigZagSoundPositions[i].SetPosition(ClosestZoePos);
		}

		ZigZagMultiEmitter.SetMultiplePositions(ZigZagSoundPositions, AkMultiPositionType::MultiSources);
	}
}