struct FDentistBossToothPasteTubeLobToothPasteActivationParams
{
	int ToothPasteLobCount;
	float DelayBetweenLobs;
	float Duration;
	AHazePlayerCharacter TargetPlayer;
}

class UDentistBossToothPasteTubeLobToothPasteCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	ADentistBossToolToothPasteTube ToothPasteTube;
	ADentistBossCake Cake;

	FDentistBossToothPasteTubeLobToothPasteActivationParams Params;

	UDentistBossSettings Settings;

	float TimeLastShotGlob;
	int ToothPasteShotCount = 0; 

	UHazeActorNetworkedSpawnPoolComponent ToothPastePool;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		Cake = Dentist.Cake;
		
		Settings = UDentistBossSettings::GetSettings(Dentist);

		ToothPastePool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(Dentist.ToothPasteGlobClass, ToothPasteTube);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossToothPasteTubeLobToothPasteActivationParams InParams)
	{
		Params = InParams;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Params.Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ToothPasteShotCount = 0;
		ToothPasteTube = Cast<ADentistBossToolToothPasteTube>(Dentist.Tools[EDentistBossTool::ToothPasteTube]);
		if(HasControl())
			ShootGlob();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		if(Time::GetGameTimeSince(TimeLastShotGlob) >= Params.DelayBetweenLobs)
			ShootGlob();
	}

	void ShootGlob()
	{
		if(ToothPasteShotCount >= Params.ToothPasteLobCount)
			return;

		TimeLastShotGlob = Time::GameTimeSeconds;

		USceneComponent ChosenTarget;
		ChosenTarget = Cake.NotGlobbedTargets[Math::RandRange(0, Cake.NotGlobbedTargets.Num()-1)];
		// float ClosestDistanceSqrd = MAX_flt;
		// for(auto Target : Cake.NotGlobbedTargets)
		// {
		// 	float DistSqrd = Target.WorldLocation.DistSquared(Params.TargetPlayer.ActorLocation);
		// 	if(DistSqrd < ClosestDistanceSqrd)
		// 	{
		// 		ChosenTarget = Target;
		// 		ClosestDistanceSqrd = DistSqrd;
		// 	}
		// }

		if(ChosenTarget == nullptr)
			return;
		
		bool bTargetIsInner = false;
		if(ChosenTarget.AttachParent == Cake.InnerToothPasteGlobTargetRoot)
			bTargetIsInner = true;
		
		auto Glob = Dentist.GetToothPasteGlob(ToothPasteTube.ToothPasteShotMuzzle.WorldLocation, FRotator::ZeroRotator);
		Glob.CrumbGetLobbed(ToothPasteTube.ToothPasteShotMuzzle, ChosenTarget, bTargetIsInner);
		Cake.ChooseGlobTarget(ChosenTarget);
		ToothPasteShotCount++;
	}
};