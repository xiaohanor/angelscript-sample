class USkylineDisableFullTreeComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	bool bStartDisabled = false;

	TArray<AActor> Actors;

	TArray<FInstigator> DisableInstigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Owner.GetAttachedActors(Actors, true, true);

		if (bStartDisabled)
			AddDisabler(this);
	}

	UFUNCTION()
	void AddDisabler(FInstigator DisableInstigator)
	{
		if (DisableInstigators.Num() == 0)
		{
			for (auto Actor : Actors)
			{
				Actor.AddActorDisable(this);
				Actor.AddActorCollisionBlock(this);
			}
		}

		DisableInstigators.Add(DisableInstigator);
	}

	UFUNCTION()
	void RemoveDisabler(FInstigator DisableInstigator)
	{
		DisableInstigators.Remove(DisableInstigator);

		if (DisableInstigators.Num() == 0)
		{
			for (auto Actor : Actors)
			{
				Actor.RemoveActorDisable(this);
				Actor.RemoveActorCollisionBlock(this);
			}
		}
	}

	UFUNCTION()
	void RemoveAllDisablers()
	{
		if (DisableInstigators.Num() > 0)
		{
			for (auto Actor : Actors)
			{
				Actor.RemoveActorDisable(this);
				Actor.RemoveActorCollisionBlock(this);
			}
		}

		DisableInstigators.Reset();
	}
};