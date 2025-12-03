// TODO: This should not be a behaviour, but rather a separate capability
class UBasicFallingBehaviour : UBasicBehaviour
{
	default CapabilityTags.Add(n"Falling");

	UBasicAIHealthComponent HealthComp;
	UHazeMovementComponent MoveComp;

	private float AirTimer;
	private float VerticalSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(IsBlocked())
		{
			AirTimer = 0;
			return;
		}
		if(IsActive())
		{
			AirTimer = 0;
			return;
		}
		if(HealthComp.IsDead())
		{
			AirTimer = 0;
			return;
		}
		if(MoveComp.IsInAir())
		{
			AirTimer += DeltaTime;
			return;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if(HealthComp.IsDead())
			return false;
		if (AirTimer < 0.5)
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
		VerticalSpeed = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AirTimer = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.IsInAir())
		{
			if(ActiveDuration > 1 && VerticalSpeed > 1000)
				HealthComp.TakeDamage(BIG_NUMBER, EDamageType::Default, Owner);
			DeactivateBehaviour();
		}
		VerticalSpeed = MoveComp.VerticalVelocity.Size();

		if(ActiveDuration > 2)
		{
			HealthComp.TakeDamage(BIG_NUMBER, EDamageType::Default, Owner);
			DeactivateBehaviour();
		}
	}
}