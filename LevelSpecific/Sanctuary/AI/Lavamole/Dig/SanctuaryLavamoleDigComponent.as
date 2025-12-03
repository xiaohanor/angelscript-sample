class USanctuaryLavamoleDigComponent : UActorComponent
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DigDownEnd();	
	}

	void DigDownStart()
	{
		auto Mole = Cast<AAISanctuaryLavamole>(Owner);
		if (Mole != nullptr)
			Mole.Bite1Comp.Disable(this);
	}

	void DigDownEnd()
	{
		Owner.AddActorCollisionBlock(this);
		Owner.AddActorVisualsBlock(this);
	}

	void DigUpStart()
	{
		Owner.RemoveActorCollisionBlock(this);
		Owner.RemoveActorVisualsBlock(this);
	}

	void DigUpEnd()
	{
		auto Mole = Cast<AAISanctuaryLavamole>(Owner);
		if (Mole != nullptr)
			Mole.Bite1Comp.Enable(this);
	}
}