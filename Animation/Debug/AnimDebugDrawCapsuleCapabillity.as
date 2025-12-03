const FConsoleVariable CVar_DrawDebugCapsule("Haze.DrawDebugCapsule", DefaultValue = 0);

class UAnimDebugDrawCapsuleCapabillity : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	UCapsuleComponent CapsuleComp;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return CVar_DrawDebugCapsule.Int > 0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return CVar_DrawDebugCapsule.Int <= 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (CVar_DrawDebugCapsule.Int > 1)
		{
			const auto TopLevelActor = GetTopLevelActor();
			CapsuleComp = UCapsuleComponent::Get(TopLevelActor);
		}
		else
		{
			CapsuleComp = UCapsuleComponent::Get(Owner);
		}

		// Disable anti-aliasing while we're drawing a debug capsule, so it is properly visible
		auto DebugViewModeManager = Cast<UDebugViewModeManager>(UDebugViewModeManager.DefaultObject);
		DebugViewModeManager.SetDebugDisableAntiAliasing(this, true);

		UAnimDebugDrawCapsuleComponent DebugDrawCapsuleComp = UAnimDebugDrawCapsuleComponent::GetOrCreate(Owner);
		DebugDrawCapsuleComp.DebugDrawCapsule(CapsuleComp);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Re-enable anti-aliasing
		auto DebugViewModeManager = Cast<UDebugViewModeManager>(UDebugViewModeManager.DefaultObject);
		DebugViewModeManager.SetDebugDisableAntiAliasing(this, false);

		UAnimDebugDrawCapsuleComponent DebugDrawCapsuleComp = UAnimDebugDrawCapsuleComponent::Get(Owner);
		if (DebugDrawCapsuleComp != nullptr)
			DebugDrawCapsuleComp.Stop();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Using a component instead since it can continue ticking/drawing while paused
	}

	private AActor GetTopLevelActor()
	{
		AActor OutActor = Owner;
		for (int i = 0; i < 10; i++)
		{
			// Check if it has a parent actor with a capsule component
			if (Owner.AttachParentActor == nullptr || UCapsuleComponent::Get(Owner.AttachParentActor) == nullptr)
				break;

			OutActor = Owner.AttachParentActor;
		}

		return OutActor;
	}
};

class UAnimDebugDrawCapsuleComponent : UActorComponent
{
	UCapsuleComponent CapsuleComp;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (CapsuleComp == nullptr)
			return;

		Debug::DrawDebugCapsule(
			CapsuleComp.WorldLocation,
			CapsuleComp.CapsuleHalfHeight,
			CapsuleComp.CapsuleRadius,
			CapsuleComp.WorldRotation,
			Thickness = 1.2);

		// Draw the forward & right vector too
		FVector ArrowLocation = CapsuleComp.WorldLocation - (CapsuleComp.UpVector * CapsuleComp.ScaledCapsuleHalfHeight);

		float ArrowSize = CapsuleComp.CapsuleRadius;
		float Thickness = CapsuleComp.CapsuleRadius / 20;
		float ArrowLenght = CapsuleComp.CapsuleRadius + (CapsuleComp.CapsuleRadius / 2);

		Debug::DrawDebugArrow(ArrowLocation, ArrowLocation + (CapsuleComp.ForwardVector * ArrowLenght), ArrowSize, FLinearColor::Red, Thickness);
		Debug::DrawDebugArrow(ArrowLocation, ArrowLocation + (CapsuleComp.RightVector * ArrowLenght), ArrowSize, FLinearColor::Green, Thickness);
	}

	void DebugDrawCapsule(UCapsuleComponent InCapsuleComp)
	{
		CapsuleComp = InCapsuleComp;
		SetTickableWhenPaused(true);
	}

	void Stop()
	{
		CapsuleComp = nullptr;
		SetTickableWhenPaused(false);
	}
}