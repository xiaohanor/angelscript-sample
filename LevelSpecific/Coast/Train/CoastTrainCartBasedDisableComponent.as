
/**
 * A disable component for use on train carts that disables based on how far players are from the cart rather than the object.
 * It also detaches the actor while it's disabled, so that the train's movement doesn't need to update the transforms all the time.
 */
class UCoastTrainCartBasedDisableComponent : UActorComponent
{
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_PostPhysics; 
	default bBlockTickOnDisable = false;

	UPROPERTY(EditAnywhere, Category = "Disabling")
	bool bAutoDisable = true;

	UPROPERTY(EditAnywhere, Category = "Disabling")
	float AutoDisableRange = 15000.0;

	/* If set, this auto disable is considered visual only, and is checked locally. This can create differences in network, so only use it where it doesn't matter (ie visuals). */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Disabling", AdvancedDisplay, Meta = (EditCondition = "bAutoDisable", EditConditionHides))
	bool bActorIsVisualOnly = false;

	private AActor AttachmentBase;
	private bool bIsAutoDisabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// If this is an auto-disable actor, disable it from the start
		if (bAutoDisable && !bActorIsVisualOnly)
		{
			bIsAutoDisabled = true;
			Owner.AddActorDisable(this);
		}

		// Find the base attachment in the level
		AttachmentBase = Owner;
		while (AttachmentBase.GetAttachParentActor() != nullptr)
			AttachmentBase = AttachmentBase.GetAttachParentActor();

		// Immediately update the auto-disable on control side
		UpdateAutoDisable();

		// Spread out ticks over time
		SetComponentTickEnabled(bAutoDisable);
		SetComponentTickInterval(Math::RandRange(0.0, 1.0));
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		if (AttachmentBase != Owner)
		{
			Owner.RootComponent.DetachFromComponent(
				EDetachmentRule::KeepRelative,
				EDetachmentRule::KeepRelative,
				EDetachmentRule::KeepRelative,
			);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		if (AttachmentBase != Owner)
		{
			Owner.RootComponent.AttachToComponent(
				AttachmentBase.RootComponent,
				NAME_None,
				EAttachmentRule::KeepRelative,
			);
		}
	}

	void UpdateAutoDisable()
	{
		// Auto disable can only be updated on the control side, or locally if visual only
		if (!bActorIsVisualOnly && !HasControl())
			return;

		FVector OwnerLocation = AttachmentBase.ActorLocation;

		const TArray<AHazePlayerCharacter>& Players = Game::Players;
		float Player0 = Players[0].ActorLocation.DistSquared(OwnerLocation);
		float Player1 = Players[1].ActorLocation.DistSquared(OwnerLocation);
		float ClosestDistanceSq = Math::Min(Player0, Player1);

		bool bShouldBeDisabled = 
			bAutoDisable
			&& AutoDisableRange > 0.0
			&& ClosestDistanceSq > Math::Square(AutoDisableRange);

		if (bShouldBeDisabled != bIsAutoDisabled)
		{
			if (bActorIsVisualOnly)
				UpdateAutoDisableState(bShouldBeDisabled);
			else
				CrumbUpdateAutoDisableState(bShouldBeDisabled);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbUpdateAutoDisableState(bool bShouldBeDisabled)
	{
		UpdateAutoDisableState(bShouldBeDisabled);
	}

	private void UpdateAutoDisableState(bool bShouldBeDisabled)
	{
		if (bShouldBeDisabled)
		{
			bIsAutoDisabled = true;
			Owner.AddActorDisable(this);
		}
		else
		{
			bIsAutoDisabled = false;
			Owner.RemoveActorDisable(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bAutoDisable)
		{
			UpdateAutoDisable();

			// Now that our initial randomized interval has passed, update every second
			SetComponentTickInterval(1.0);
		}
		else
		{
			// No longer auto-disabling, stop updating
			SetComponentTickEnabled(false);
		}
	}
}
