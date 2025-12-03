namespace ExampleDevToggles
{
	const FHazeDevToggleBool ExampleShouldBeActive;

	// A toggle group appear as a radio button. 

	const FHazeDevToggleCategory SomeDrawingCategory = FHazeDevToggleCategory(n"Drawing");
	const FHazeDevToggleGroup DrawingMode = FHazeDevToggleGroup(SomeDrawingCategory, n"Drawing Mode");
	const FHazeDevToggleOption DrawmodeBox = FHazeDevToggleOption(DrawingMode, n"Drawmode Box");
	const FHazeDevToggleOption DrawmodeSphere = FHazeDevToggleOption(DrawingMode, n"Draw Sphere", true); // If you don't specify a default option with, the first one is used.
	const FHazeDevToggleOption DrawmodeCoordinateSystem = FHazeDevToggleOption(DrawingMode, n"Drawmode CoordinateSystem");

	const FHazeDevToggleBool DrawSomething;
	const FHazeDevToggleBool DrawTheOtherThing;

	const FHazeDevToggleBoolPerPlayer DrawPlayerCapsule;

}

class UExample_SomeGameplayCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ExampleDevToggles::DrawingMode.BindOnChanged(this, n"OnDrawingModeChanged");

		ExampleDevToggles::ExampleShouldBeActive.BindOnChanged(this, n"OnToggleBoolChanged");
		ExampleDevToggles::ExampleShouldBeActive.MakeVisible();

		// You can call MakeVisible on a whole category too!
		ExampleDevToggles::SomeDrawingCategory.MakeVisible();

		// PRESET sets everyhing to true / option when clicked!
		FHazeDevTogglePreset DrawAllPreset = FHazeDevTogglePreset(n"Debug Draw All The Things");
		DrawAllPreset.Add(ExampleDevToggles::DrawSomething);
		DrawAllPreset.Add(ExampleDevToggles::DrawTheOtherThing);
		DrawAllPreset.Add(ExampleDevToggles::DrawmodeSphere);
		DrawAllPreset.Add(ExampleDevToggles::DrawPlayerCapsule);
	}

	UFUNCTION()
	private void OnDrawingModeChanged(FName NewState)
	{
		PrintToScreen("My new drawing mode " + NewState.ToString());
	}

	UFUNCTION()
	private void OnToggleBoolChanged(bool bNewState)
	{
		PrintToScreen("My toggle was changed to " + bNewState);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!ExampleDevToggles::ExampleShouldBeActive.IsEnabled())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!ExampleDevToggles::ExampleShouldBeActive.IsEnabled())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ExampleDevToggles::DrawmodeSphere.IsEnabled())
			Debug::DrawDebugSphere(Owner.ActorLocation);
		if (ExampleDevToggles::DrawmodeBox.IsEnabled())
			Debug::DrawDebugBox(Owner.ActorLocation, FVector::OneVector * 100.0);
		if (ExampleDevToggles::DrawmodeCoordinateSystem.IsEnabled())
			Debug::DrawDebugCoordinateSystem(Owner.ActorLocation, Owner.ActorRotation, 100.0);

		if (ExampleDevToggles::DrawPlayerCapsule.IsEnabled(Player))
			Debug::DrawDebugCapsule(Player.ActorCenterLocation, Player.CapsuleComponent.CapsuleHalfHeight, Player.CapsuleComponent.CapsuleRadius, Player.ActorRotation, Player.GetPlayerUIColor());
	}
};

// -------------------------------------------------------------------------------------------------------
// Combine DevToggle Group / Option with action queues!

namespace ExampleDevToggles
{
	const FHazeDevToggleCategory ExampleCategory = FHazeDevToggleCategory(n"Example");
	const FHazeDevToggleGroup DebugActionType = FHazeDevToggleGroup(ExampleCategory, n"Debug Action Type");
	const FHazeDevToggleOption DebugActionNone = FHazeDevToggleOption(DebugActionType, n"None", true);
	const FHazeDevToggleOption DebugActionAttackPattern1 = FHazeDevToggleOption(DebugActionType, n"Attack Pattern 1");
	const FHazeDevToggleOption DebugActionAttackPattern2 = FHazeDevToggleOption(DebugActionType, n"Attack Pattern 2");
	const FHazeDevToggleOption DebugActionAttackPattern3 = FHazeDevToggleOption(DebugActionType, n"Attack Pattern 3");
}

class UExample_SomeActionQueueingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	FHazeActionQueue ActionQueue;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ActionQueue.Initialize(Owner);
		ExampleDevToggles::DebugActionType.MakeVisible();

		// Empty queue when option is changed to force refresh it :)
		ExampleDevToggles::DebugActionType.BindOnChanged(this, n"ToggleOptionChanged");
	}

	UFUNCTION()
	private void ToggleOptionChanged(FName NewState)
	{
		ActionQueue.Empty();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!ActionQueue.IsEmpty())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!ActionQueue.IsEmpty())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (ExampleDevToggles::DebugActionNone.IsEnabled())
		{
			// Default Queueing Behavior
			AttackPattern1();
			AttackPattern2();
			AttackPattern3();
		}
		if (ExampleDevToggles::DebugActionAttackPattern1.IsEnabled())
			AttackPattern1();
		if (ExampleDevToggles::DebugActionAttackPattern2.IsEnabled())
			AttackPattern2();
		if (ExampleDevToggles::DebugActionAttackPattern3.IsEnabled())
			AttackPattern3();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ActionQueue.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ActionQueue.Update(DeltaTime);
	}

	void AttackPattern1()
	{
		ActionQueue.Idle(0.2);
		ActionQueue.Event(this, ShootFunction);
		ActionQueue.Idle(0.2);
		ActionQueue.Event(this, ShootFunction);
		ActionQueue.Idle(1);
	}


	void AttackPattern2()
	{
		ActionQueue.Idle(0.2);
		ActionQueue.Event(this, MeleeFunction);
		ActionQueue.Idle(0.2);
		ActionQueue.Event(this, MeleeFunction);
		ActionQueue.Idle(1);
	}

	void AttackPattern3()
	{
		ActionQueue.Idle(0.2);
		ActionQueue.Event(this, MeleeFunction);
		ActionQueue.Idle(0.2);
		ActionQueue.Event(this, ShootFunction);
		ActionQueue.Idle(0.2);
		ActionQueue.Duration(5.0, this, DoTheBarrelRollFunction);
		ActionQueue.Idle(1);
	}

	FName MeleeFunction = n"Melee";
	UFUNCTION()
	void Melee()
	{
		PrintToScreen("Hiyyyaaa!");
	}

	FName ShootFunction = n"Shoot";
	UFUNCTION()
	void Shoot()
	{
		PrintToScreen("Pew pew");
	}

	FName DoTheBarrelRollFunction = n"DoTheBarrelRoll";
	UFUNCTION()
	private void DoTheBarrelRoll(float Alpha)
	{
		PrintToScreen("Barrel rolling " + Alpha + "%");
	}
};