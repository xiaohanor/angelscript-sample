class UGoatDevourOpenMouthCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UGenericGoatPlayerComponent GoatComp;
	UGoatDevourPlayerComponent DevourComp;

	bool bTravellingToMouth = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GoatComp = UGenericGoatPlayerComponent::Get(Player);
		DevourComp = UGoatDevourPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		if (DevourComp.CurrentDevourResponseComp != nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bTravellingToMouth)
			return false;

		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		if (DevourComp.CurrentDevourResponseComp != nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bTravellingToMouth = false;
		DevourComp.OpenMouth();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DevourComp.CloseMouth();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bTravellingToMouth)
			return;

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnorePlayers();
		Trace.IgnoreActor(DevourComp.CurrentGoat);
		FRotator CapsuleRot = Player.ActorRotation + (FRotator(90.0, 0.0, 0.0));
		Trace.UseCapsuleShape(200.0, 500.0, FQuat(CapsuleRot));
		
		FHitResultArray HitResultArray;
		HitResultArray = Trace.QueryTraceMulti(DevourComp.CurrentGoat.MouthComp.WorldLocation + (Player.ActorForwardVector * 500.0), DevourComp.CurrentGoat.MouthComp.WorldLocation + (Player.ActorForwardVector * 501.0));
		
		for (FHitResult Hit : HitResultArray.HitResults)
		{
			UGoatDevourResponseComponent DevourResponseComp = UGoatDevourResponseComponent::Get(Hit.Actor);
			if (DevourResponseComp != nullptr && DevourResponseComp.CanBeDevoured())
			{
				DevourResponseComp.GetDevoured(DevourComp.CurrentGoat);
				if (!DevourResponseComp.bDestroyOnDevour && !DevourResponseComp.bDisableOnDevour)
				{
					bTravellingToMouth = true;
					DevourResponseComp.OnReachedMouth.AddUFunction(this, n"ReachedMouth");
					DevourComp.CurrentDevourResponseComp = DevourResponseComp;
					break;
				}
			}
		}
	}

	UFUNCTION()
	private void ReachedMouth()
	{
		bTravellingToMouth = false;
	}
}