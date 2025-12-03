class USkylineGeckoResistWhipBehaviour : UBasicBehaviour
{
	UGravityWhipTargetComponent WhipTarget;
	UGravityWhipResponseComponent WhipResponse;
	USkylineGeckoSettings GeckoSettings;
	AHazeCharacter Character;
	UGravityWhipUserComponent WhipUser;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GeckoSettings = USkylineGeckoSettings::GetSettings(Owner);
		WhipTarget = UGravityWhipTargetComponent::Get(Owner);
		WhipResponse = UGravityWhipResponseComponent::Get(Owner);
		Character = Cast<AHazeCharacter>(Owner);

		WhipResponse.OnGrabbed.AddUFunction(this, n"OnGrabbed");
	}

	UFUNCTION()
	private void OnGrabbed(UGravityWhipUserComponent UserComponent,
	                       UGravityWhipTargetComponent TargetComponent,
						   TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		if(Owner.IsCapabilityTagBlocked(SkylineAICapabilityTags::GravityWhippable))
			WhipUser = UserComponent;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(WhipUser == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		WhipUser = nullptr;
		WhipTarget.Enable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(FeatureTagGecko::ResistWhip, EBasicBehaviourPriority::Medium, this, GeckoSettings.ResistWhipDuration);
		Owner.SetAnimTrigger(n"TookDamage");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration > GeckoSettings.ResistWhipDuration)
		{
			auto Actor = Cast<AHazeActor>(Owner);
			for (int i = WhipResponse.Grabs.Num() - 1; i >= 0; --i)
				WhipResponse.Grabs[i].UserComponent.Release(Actor);

			WhipTarget.Disable(this);

			auto WhipperPlayer = Cast<AHazePlayerCharacter>(WhipUser.Owner);
			if(WhipperPlayer != nullptr)
			{
				FStumble Stumble;
				FVector Dir = (WhipperPlayer.ActorLocation - Owner.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
				Stumble.Move = Dir * 100;
				Stumble.Duration = 1;
				WhipperPlayer.ApplyStumble(Stumble);
			}
			DeactivateBehaviour();
		}
	}
}