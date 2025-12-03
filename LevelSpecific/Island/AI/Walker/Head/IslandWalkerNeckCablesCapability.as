class UIslandWalkerNeckCablesSettings : UHazeComposableSettings
{
	// Number of cables. Block and unblock companion cable capability to update this.
	UPROPERTY(Category = "Cables")
	int NumCables = 12;

	UPROPERTY(Category = "Cables")
	float CableOriginRadius = 38.0;

	UPROPERTY(Category = "Cables")
	float CableRadiusHeadScale = 3.5;

	UPROPERTY(Category = "Cables")
	float RestingLength = 600.0;

	UPROPERTY(Category = "Cables")
	float NearFraction = 0.3;
	UPROPERTY(Category = "Cables")
	float NearStiffness = 200.0;
	UPROPERTY(Category = "Cables")
	float NearDamping = 0.9;

	UPROPERTY(Category = "Cables")
	float FarFraction = 0.6;
	UPROPERTY(Category = "Cables")
	float FarStiffness = 6.0;
	UPROPERTY(Category = "Cables")
	float FarDamping = 0.3;

	UPROPERTY(Category = "Cables")
	float ReachEndDuration = 0.2;
	UPROPERTY(Category = "Cables")
	float ReachFarStiffness = 200.0;
	UPROPERTY(Category = "Cables")
	float ReachFarDamping = 0.3;

	UPROPERTY(Category = "Cables")
	float DetachedGravity = 982.0 * 2.0;

	UPROPERTY(Category = "Cables")
	float DetachedStretchFactor = 10.0;	
};


class UIslandWalkerNeckCablesCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default CapabilityTags.Add(n"Cables");
	default TickGroup = EHazeTickGroup::AfterGameplay;

	UIslandWalkerHeadComponent HeadComp;
	UBasicAICharacterMovementComponent MoveComp;
	UIslandWalkerComponent SuspendComp;
	UIslandWalkerNeckCablesSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HeadComp = UIslandWalkerHeadComponent::Get(Owner); 
		HeadComp.HeadCableOrigin = UIslandWalkerCableOriginComponent::Get(Owner);	
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);	
		SuspendComp = UIslandWalkerComponent::Get(HeadComp.NeckCableOrigin.Owner);
		Settings = UIslandWalkerNeckCablesSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Settings.NumCables == 0)
			return false;
		if (HeadComp.State == EIslandWalkerHeadState::Attached)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Settings.NumCables == 0)
			return true;
		if (HeadComp.State == EIslandWalkerHeadState::Attached)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FTransform HeadTransform = HeadComp.HeadCableOrigin.WorldTransform;
		FTransform NeckTransform = HeadComp.NeckCableOrigin.WorldTransform;
		float Interval = 2.0 * PI / float(Settings.NumCables);
		for (int i = 0; i < Settings.NumCables; i++)
		{
			FIslandWalkerNeckCable Cable;
			Cable.Effect = Niagara::SpawnLoopingNiagaraSystemAttached(HeadComp.NeckCableFX, Owner.RootComponent);
			FVector Dir = FVector(0.0, Math::Cos(i * Interval), Math::Sin(i * Interval));
			Cable.LocalOrigin = Dir * Settings.CableOriginRadius * Math::RandRange(0.7, 1.3);
			FVector HeadLoc = HeadTransform.TransformPosition(Cable.LocalOrigin * Settings.CableRadiusHeadScale);
			FVector NeckLoc = NeckTransform.TransformPosition(FVector(Cable.LocalOrigin.X, -Cable.LocalOrigin.Y, Cable.LocalOrigin.Z));
			Cable.AccNear.SnapTo(HeadLoc);
			Cable.AccFar.SnapTo(NeckLoc);
			Cable.AccNeck.SnapTo(NeckLoc);
			HeadComp.Cables.Add(Cable);
		}	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (FIslandWalkerNeckCable Cable : HeadComp.Cables)
		{
			Cable.Effect.Deactivate();
		}
		HeadComp.Cables.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FTransform HeadTransform = HeadComp.HeadCableOrigin.WorldTransform;
		FTransform NeckTransform = HeadComp.NeckCableOrigin.WorldTransform;

		for (FIslandWalkerNeckCable& Cable : HeadComp.Cables)
		{
			FVector HeadLoc = HeadTransform.TransformPosition(Cable.LocalOrigin * Settings.CableRadiusHeadScale);
			FVector NeckLoc = NeckTransform.TransformPosition(FVector(Cable.LocalOrigin.X, -Cable.LocalOrigin.Y, Cable.LocalOrigin.Z));
			float Length = (NeckLoc - HeadLoc).Size();

			FVector HeadDir = HeadTransform.Rotation.ForwardVector;
			
			if (HeadComp.State == EIslandWalkerHeadState::Detached)
			{
				Cable.AccHead.SnapTo(HeadLoc, Owner.ActorVelocity);	
				Cable.AccNear.SpringTo(HeadLoc + HeadDir * Length * Settings.NearFraction, Settings.NearStiffness, Settings.NearDamping, DeltaTime);
				if (Cable.bReach)
				{
					Cable.AccNeck.AccelerateTo(Cable.ReachLocation, Settings.ReachEndDuration, DeltaTime);
					Cable.AccFar.SpringTo(Cable.ReachEndControl, Settings.ReachFarStiffness, Settings.ReachFarDamping, DeltaTime);
				}
				else
				{
					// Cables are detached, follow head with gravity
					float FrictionFactor = Math::Pow(Math::Exp(-0.25), DeltaTime);
					UpdateLoose(Cable.AccFar, FrictionFactor, HeadLoc, Settings.RestingLength * 0.75, DeltaTime);
					UpdateLoose(Cable.AccNeck, FrictionFactor, HeadLoc, Settings.RestingLength, DeltaTime);
				}
			}
			else if (HeadComp.State != EIslandWalkerHeadState::Destroyed)
			{
				// Cables are still attached to neck
				Cable.AccHead.SnapTo(HeadLoc, Owner.ActorVelocity);	
				Cable.AccNear.SpringTo(HeadLoc + HeadDir * Length * Settings.NearFraction, Settings.NearStiffness, Settings.NearDamping, DeltaTime);
				FVector NeckDir = NeckTransform.Rotation.ForwardVector;
				Cable.AccFar.SpringTo(NeckLoc + NeckDir * Length * (1.0 - Settings.FarFraction), Settings.FarStiffness, Settings.FarDamping, DeltaTime);
				Cable.AccNeck.SnapTo(NeckLoc, Owner.ActorVelocity);
			}
			else
			{
				// Head has been destroyed, cables are cut loose
				float FrictionFactor = Math::Pow(Math::Exp(-0.25), DeltaTime);
				UpdateLoose(Cable.AccHead, FrictionFactor, Cable.AccNear.Value, Settings.RestingLength * 0.3, DeltaTime);
				UpdateLoose(Cable.AccNear, FrictionFactor, Cable.AccHead.Value, Settings.RestingLength * 0.3, DeltaTime);
				UpdateLoose(Cable.AccFar, FrictionFactor, Cable.AccNear.Value, Settings.RestingLength * 0.3, DeltaTime);
				UpdateLoose(Cable.AccNeck, FrictionFactor, Cable.AccFar.Value, Settings.RestingLength * 0.5, DeltaTime);
			}

			Cable.Effect.SetVectorParameter(n"P0", Cable.AccHead.Value); 
			Cable.Effect.SetVectorParameter(n"P1", Cable.AccNear.Value); 
			Cable.Effect.SetVectorParameter(n"P2", Cable.AccFar.Value); 
			Cable.Effect.SetVectorParameter(n"P3", Cable.AccNeck.Value); 
		}
	}

	void UpdateLoose(FHazeAcceleratedVector& AccPosition, float FrictionFactor, FVector HeadLoc, float RestingLength, float DeltaTime)
	{
		if (!HeadLoc.IsWithinDist(AccPosition.Value, RestingLength))
		{
			// Rubberband towards head when stretched past resting limit
			FVector ToHead = (HeadLoc - AccPosition.Value);
			float HeadDistance = ToHead.Size();
			float Stretch = HeadDistance - RestingLength;
			AccPosition.Velocity += (ToHead / HeadDistance) * Stretch * Settings.DetachedStretchFactor * DeltaTime; 
		}

		// Fall
		AccPosition.Velocity.Z -= Settings.DetachedGravity * DeltaTime;
		
		// Friction
		AccPosition.Velocity *= FrictionFactor;

		AccPosition.Value += AccPosition.Velocity * DeltaTime;
		if (AccPosition.Value.Z < SuspendComp.ArenaLimits.Height)
		{
			FVector LandLoc = AccPosition.Value;
			LandLoc.Z = SuspendComp.ArenaLimits.Height;
			AccPosition.SnapTo(LandLoc);					
		}
	}
}
