/**
 * A component that can automatically disable the actor when both players are far away.
 */
class UDisableComponent : UActorComponent
{
	access EditOnly = private, * (editdefaults, readonly);

	/**
	 * Whether to use auto-disabling currently. 
	 * If true, component will try to deactivate when both players are outside the 'AutoDisableRange'
	 */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Disabling")
	access:EditOnly bool bAutoDisable = false;

	/* When the actor is more than this distance away from both players. it will get disabled automatically. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Disabling", Meta = (EditCondition = "bAutoDisable", EditConditionHides))
	float AutoDisableRange = 5000.0;

	UPROPERTY(EditAnywhere, Category = "Disabling", AdvancedDisplay, Meta = (EditCondition = "bAutoDisable", EditConditionHides))
	bool bDrawDisableRange = true;

	UPROPERTY(EditAnywhere, Category = "Disabling", AdvancedDisplay, Meta = (EditCondition = "bAutoDisable", EditConditionHides))
	bool bDrawLinkedActors = true;

	/* While this actor is auto-disabled, the specified linked actors will also be disabled automatically. */
	UPROPERTY(Category = "Disabling", BlueprintHidden, EditInstanceOnly, Meta = (EditCondition = "bAutoDisable", EditConditionHides))
	TArray<TSoftObjectPtr<AHazeActor>> AutoDisableLinkedActors;

	/* If set, this auto disable is considered visual only, and is checked locally. This can create differences in network, so only use it where it doesn't matter (ie visuals). */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Disabling", AdvancedDisplay, Meta = (EditCondition = "bAutoDisable", EditConditionHides))
	bool bActorIsVisualOnly = false;

	/* Whether to automatically disable this actor from the start. This initial disable will have StartDisabledInstigator as its Disabler/Instigator. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Disabling")
	bool bStartDisabled = false;

	/* Instigator to use for the actor being disabled at the start. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Disabling", Meta = (EditCondition = "bStartDisabled", EditConditionHides))
	FName StartDisabledInstigator = n"StartDisabled";

	private bool bIsAutoDisabled = false;
	private TArray<AHazeActor> AppliedLinkedDisables;
	private bool bHasBegunPlay = false;
	private float RealTimeLastAutoDisableChange;
	int SingletonRegistrationIndex = -1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bHasBegunPlay = true;

		// We do not want to disable an actor that is created by a level sequence
		if (Owner.ActorHasTag(n"SequencerActor"))
			bAutoDisable = false;

		// Apply the disable when we want to start disabled
		if (bStartDisabled)
			Owner.AddActorDisable(StartDisabledInstigator);

		// If this is an auto-disable actor placed in a map, disable it from the start
		if (bAutoDisable && !bActorIsVisualOnly && !Owner.Level.IsDynamicSpawnLevel())
		{
			UpdateAutoDisableState(true);

			// Reset timer so the first update can still flip it back
			RealTimeLastAutoDisableChange = 0.0;
		}

		// Immediately update the auto-disable on control side
		if (bAutoDisable)
		{
			RegisterToSingleton();
			if (!Game::IsInLoadingScreen() && Progress::HasActivatedAnyProgressPoint())
				UpdateAutoDisable();
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		UnregisterFromSingleton();
	}

	private void RegisterToSingleton()
	{
		if (SingletonRegistrationIndex == -1)
		{
			auto Singleton = Game::GetSingleton(UDisableComponentSingleton);
			SingletonRegistrationIndex = Singleton.AutoDisableComponents.Num();
			Singleton.NewlyAddedAutoDisableComponents.Add(this);
			Singleton.AutoDisableComponents.Add(this);
		}
	}

	private void UnregisterFromSingleton()
	{
		if (SingletonRegistrationIndex != -1)
		{
			auto Singleton = Game::GetSingleton(UDisableComponentSingleton);

			int LastIndex = Singleton.AutoDisableComponents.Num() - 1;
			if (SingletonRegistrationIndex != LastIndex)
			{
				UDisableComponent LastComp = Singleton.AutoDisableComponents[LastIndex];
				Singleton.AutoDisableComponents[SingletonRegistrationIndex] = LastComp;
				LastComp.SingletonRegistrationIndex = SingletonRegistrationIndex;
			}

			Singleton.AutoDisableComponents.RemoveAt(LastIndex);
			SingletonRegistrationIndex = -1;
		}
	}

	/**
	 * Disable the actor, and all AutoDisableLinkedActors.
	 */
	UFUNCTION(BlueprintCallable)
	void AddActorDisableToActorAndLinkedActors(FInstigator Instigator)
	{
		Owner.AddActorDisable(Instigator);

		for (auto ActorRef : AutoDisableLinkedActors)
		{
			AHazeActor LinkedActor = ActorRef.Get();
			if (LinkedActor == nullptr)
				continue;

			LinkedActor.AddActorDisable(Instigator);
		}
	}

	/**
	 * Remove a disabling instigator from the actor, and all AutoDisableLinkedActors.
	 */
	UFUNCTION(BlueprintCallable)
	void RemoveActorDisableFromActorAndLinkedActors(FInstigator Instigator)
	{
		Owner.RemoveActorDisable(Instigator);
		
		for (auto ActorRef : AutoDisableLinkedActors)
		{
			AHazeActor LinkedActor = ActorRef.Get();
			if (LinkedActor == nullptr)
				continue;

			LinkedActor.RemoveActorDisable(Instigator);
		}
	}

	/**
	 * Add an actor to AutoDisableLinkedActors after the game has started.
	 * Will disable LinkedActor if this disable component has already been disabled.
	 */
	void LateAddAutoDisableLinkedActor(TSoftObjectPtr<AHazeActor> LinkedActor)
	{
		if(LinkedActor.IsNull())
			return;

		if(AutoDisableLinkedActors.AddUnique(LinkedActor))
		{
			if(bIsAutoDisabled && LinkedActor.IsValid())
			{
				// We are disabled, so we should disable this linked actor as well
				LinkedActor.Get().AddActorDisable(this);
				AppliedLinkedDisables.Add(LinkedActor.Get());
			}
		}
	}

	/**
	 * Remove an actor from AutoDisableLinkedActors after the game has started.
	 * Will enable LinkedActor if it was previously auto disabled by this component.
	 */
	void LateRemoveAutoDisableLinkedActor(TSoftObjectPtr<AHazeActor> LinkedActor)
	{
		if(LinkedActor.IsNull())
			return;

		if(AutoDisableLinkedActors.RemoveSingleSwap(LinkedActor) >= 0)
		{
			// If we had previously disabled this actor, enable it
			if(bIsAutoDisabled && AppliedLinkedDisables.RemoveSingleSwap(LinkedActor.Get()) >= 0)
			{
				LinkedActor.Get().RemoveActorDisable(this);
			}
		}
	}

	void SetEnableAutoDisable(bool bEnabled)
	{
		bAutoDisable = bEnabled;

		if (bHasBegunPlay)
		{
			UpdateAutoDisable();
			if (bAutoDisable)
				RegisterToSingleton();
			else
				UnregisterFromSingleton();
		}
	}

	void UpdateAutoDisable()
	{
		FVector OwnerLocation = Owner.ActorLocation;
		const TArray<AHazePlayerCharacter>& Players = Game::Players;
		float ClosestDistanceSq;
		if (Players.Num() != 0)
		{
			// Use the closest distance to either of the players
			float Player0 = Players[0].ActorLocation.DistSquared(OwnerLocation);
			float Player1 = Players[1].ActorLocation.DistSquared(OwnerLocation);
			ClosestDistanceSq = Math::Min(Player0, Player1);
		}
		else
		{
			// We don't have any players yet, probably we are on the main menu,
			// just assume we should never be disabled.
			ClosestDistanceSq = 0;
		}

		UpdateAutoDisable(ClosestDistanceSq);
	}

	void UpdateAutoDisable(float ClosestDistanceSq)
	{
		// Auto disable can only be updated on the control side, or locally if visual only
		if (!bActorIsVisualOnly && !HasControl())
			return;

		bool bShouldBeDisabled = 
			bAutoDisable
			&& AutoDisableRange > 0.0
			&& ClosestDistanceSq > Math::Square(AutoDisableRange);

		if (bShouldBeDisabled != bIsAutoDisabled)
		{
			if (bActorIsVisualOnly)
			{
				UpdateAutoDisableState(bShouldBeDisabled);
			}
			else
			{
				// Don't allow auto disable state to change super ofter if it's network synced
				if (RealTimeLastAutoDisableChange == 0.0 || Time::GetRealTimeSince(RealTimeLastAutoDisableChange) > 0.5)
					CrumbUpdateAutoDisableState(bShouldBeDisabled);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbUpdateAutoDisableState(bool bShouldBeDisabled)
	{
		if (GetWorld() != nullptr)
			UpdateAutoDisableState(bShouldBeDisabled);
	}

	private void UpdateAutoDisableState(bool bShouldBeDisabled)
	{
		RealTimeLastAutoDisableChange = Time::RealTimeSeconds;
		if (bShouldBeDisabled)
		{
			bIsAutoDisabled = true;
			AddAutoDisableOwner();

			for (auto ActorRef : AutoDisableLinkedActors)
			{
				AHazeActor LinkedActor = ActorRef.Get();
				if (LinkedActor != nullptr)
				{
					LinkedActor.AddActorDisable(this);
					AppliedLinkedDisables.Add(LinkedActor);
				}
			}
		}
		else
		{
			bIsAutoDisabled = false;
			RemoveAutoDisableOwner();

			for (AHazeActor LinkedActor : AppliedLinkedDisables)
				LinkedActor.RemoveActorDisable(this);
			AppliedLinkedDisables.Reset();
		}
	}

	protected void AddAutoDisableOwner()
	{
		Owner.AddActorDisable(this);
	}

	protected void RemoveAutoDisableOwner()
	{
		Owner.RemoveActorDisable(this);
	}

#if EDITOR
	UFUNCTION(CallInEditor, Category = "Disabling")
	protected void LinkAttachedActors()
	{
		TArray<AActor> AttachedActors;
		Owner.GetAttachedActors(AttachedActors, true, true);

		for(auto AttachedActor : AttachedActors)
		{
			auto AttachedHazeActor = Cast<AHazeActor>(AttachedActor);
			if(AttachedHazeActor == nullptr)
				continue;

			AutoDisableLinkedActors.AddUnique(AttachedHazeActor);
		}
	}

	void CopyFrom(const UDisableComponent Other)
	{
		bAutoDisable = Other.bAutoDisable;
		AutoDisableRange = Other.AutoDisableRange;
		AutoDisableLinkedActors = Other.AutoDisableLinkedActors;
		bActorIsVisualOnly = Other.bActorIsVisualOnly;
		bStartDisabled = Other.bStartDisabled;
		StartDisabledInstigator = Other.StartDisabledInstigator;
	}
#endif
};

class UDisableComponentSingleton : UHazeSingleton
{
	TArray<UDisableComponent> AutoDisableComponents;
	TArray<UDisableComponent> NewlyAddedAutoDisableComponents;
	int UpdateIndex = 0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (AutoDisableComponents.Num() == 0)
			return;
		if (Game::Mio == nullptr)
			return;
		if (Game::Zoe == nullptr)
			return;
		if (Game::IsPausedForAnyReason())
			return;

		FVector MioLocation = Game::Mio.ActorLocation;
		FVector ZoeLocation = Game::Zoe.ActorLocation;

		int DisableCompCount = AutoDisableComponents.Num();
		int UpdateCount = Math::Max(
			Math::IntegerDivisionTrunc(DisableCompCount, 30),
			15
		);
		UpdateCount = Math::Min(UpdateCount, DisableCompCount);

		for (int i = 0; i < UpdateCount; ++i)
		{
			UpdateIndex = (UpdateIndex + 1) % DisableCompCount;

			auto DisableComp = AutoDisableComponents[UpdateIndex];
			if (DisableComp == nullptr)
			{
				check(false);
				continue;
			}

			FVector CompLocation = DisableComp.Owner.ActorLocation;
			float MinDist = Math::Min(
				CompLocation.DistSquared(MioLocation),
				CompLocation.DistSquared(ZoeLocation),
			);

			DisableComp.UpdateAutoDisable(MinDist);
		}

		if (NewlyAddedAutoDisableComponents.Num() != 0)
		{
			for (auto DisableComp : NewlyAddedAutoDisableComponents)
			{
				if (!IsValid(DisableComp))
					continue;
				FVector CompLocation = DisableComp.Owner.ActorLocation;
				float MinDist = Math::Min(
					CompLocation.DistSquared(MioLocation),
					CompLocation.DistSquared(ZoeLocation),
				);

				DisableComp.UpdateAutoDisable(MinDist);
			}

			NewlyAddedAutoDisableComponents.Reset();
		}
	}
}