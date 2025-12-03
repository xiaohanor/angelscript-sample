class USummitMageTotemBehaviour : UBasicBehaviour
{
	AAISummitMage SummitMage;

	UGentlemanTokenHolderComponent TokenHolder; 

	float AttackTime;
	float AttackDuration = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SummitMage = Cast<AAISummitMage>(Owner);
		TokenHolder = UGentlemanTokenHolderComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;

		if (!TargetComp.HasValidTarget())
			return false;
		
		if (SummitMage.Totem != nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		TokenHolder.bProtectedToken = true;
		AttackTime = Time::GameTimeSeconds + AttackDuration;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		TargetComp.GentlemanComponent.ReleaseToken(GentlemanToken::Ranged, Owner, 0.5);
		TokenHolder.bProtectedToken = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Debug::DrawDebugSphere(Owner.ActorCenterLocation, 200.0, LineColor = FLinearColor::Purple);

		if (Time::GameTimeSeconds > AttackTime)
		{
			SummitMage.SpawnTotem();
			DeactivateBehaviour();
		}
	}	
}