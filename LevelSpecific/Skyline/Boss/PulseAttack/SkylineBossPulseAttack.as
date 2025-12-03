struct FSkylineBossPulseNode
{
	UPROPERTY()
	FVector StartLocation;
	UPROPERTY()
	FVector EndLocation;
	UPROPERTY()
	bool Ended;
}


UCLASS(Abstract)
class ASkylineBossPulseAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve RadiusCurve;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve HeightCurve;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve SpeedCurve;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve OpacityCurve;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem NiagaraSystem;

	UPROPERTY()
	TArray<FSkylineBossPulseNode> Nodes;

	UNiagaraComponent Vfx;

	const int NodeCount = 8;

	const float ArcAngle = 4000;

	const float DamageWidth = 30;

	const float MaxSpeed = 4000;

	const float BeamWidth = 0.75;
	
	const float TotalDistance = 10000;
	
	float CurrentRadius = 0;
	float MoveSpeed = 0;
	float DistMoved = 0;
	float StartHeight = 0;

	TPerPlayer<bool> bWasPlayerWithinArc;

	FVector Origin;
	FVector Destination;
	FVector ControlPoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bWasPlayerWithinArc[Game::Mio] = false;
		bWasPlayerWithinArc[Game::Zoe] = false;
		
		for(int i = 0; i < NodeCount; i++)
			Nodes.Add(FSkylineBossPulseNode());

		USkylineBossPulseAttackEventHandler::Trigger_OnPulseStart(this);

		StartHeight = ActorLocation.Z;

		Vfx = Niagara::SpawnLoopingNiagaraSystemAttached(NiagaraSystem, AttachmentRoot);
		Vfx.SetFloatParameter(n"BeamWidth", BeamWidth);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CheckPlayerCollision();

		MoveSpeed = SpeedCurve.GetFloatValue(DistMoved / TotalDistance) * MaxSpeed;
		CurrentRadius = RadiusCurve.GetFloatValue(DistMoved);

		Origin = ActorLocation - ActorRightVector * CurrentRadius;
		Destination = ActorLocation + ActorRightVector * CurrentRadius;
		ControlPoint = (Origin + Destination) / 2 + ActorForwardVector * (CurrentRadius);

		for(int i = 0; i < NodeCount; i++)
		{
			FSkylineBossPulseNode& Node = Nodes[i];
			FVector StartLocation = BezierCurve::GetLocation_1CP(Origin, ControlPoint, Destination, float(i) / float(NodeCount));
			Node.StartLocation = StartLocation;
		}

		FVector NewLocation = ActorLocation + ActorForwardVector * MoveSpeed * DeltaSeconds;
		NewLocation.Z = StartHeight + HeightCurve.GetFloatValue(DistMoved);
		SetActorLocation(NewLocation);

		DistMoved += MoveSpeed * DeltaSeconds;

		UpdateVfx();

		if(DistMoved >= TotalDistance)
		{
			USkylineBossPulseAttackEventHandler::Trigger_OnPulseStop(this);
			DestroyActor();
		}
	}

	UFUNCTION(BlueprintPure)
	TArray<FVector> GetActiveNodeStartLocations(const FVector Offset = FVector::ZeroVector) const
	{
		TArray<FVector> StartLocations;
		StartLocations.Reserve(Nodes.Num());

		if(Nodes.Num() <= 0)
			return StartLocations;

		for(int i = 0; i < Nodes.Num(); i++)
		{
			auto& NodeIter = Nodes[i];
			StartLocations.Add(NodeIter.StartLocation + Offset);
		}

		return StartLocations;
	}

	void UpdateVfx()
	{
		if(Vfx == nullptr)
			return;
		
		const float Alpha = Math::Saturate(DistMoved / TotalDistance);
		Vfx.SetVariableVec3(n"BeamStart", Origin);
		Vfx.SetVariableVec3(n"BeamStartTangent", Origin);
		Vfx.SetVariableVec3(n"BeamEnd", Destination);
		Vfx.SetVariableVec3(n"BeamEndTangent", ControlPoint);
		Vfx.SetFloatParameter(n"Opacity", OpacityCurve.GetFloatValue(Alpha));
		NiagaraDataInterfaceArray::SetNiagaraArrayVector(Vfx, n"BeamLocations", GetActiveNodeStartLocations());
	}

	void CheckPlayerCollision()
	{
		if(CurrentRadius < DamageWidth)
			return;

		for(auto Player : Game::Players)
		{
			FVector PlayerRelativeLocation = ActorTransform.InverseTransformPosition(Player.ActorLocation);

			const bool bWasWithinArc = bWasPlayerWithinArc[Player];
			bWasPlayerWithinArc[Player] = false;

			if(PlayerRelativeLocation.Y < -CurrentRadius * 0.95)
				continue;

			if(PlayerRelativeLocation.Y > CurrentRadius * 0.95)
				continue;
			
			float Alpha = (PlayerRelativeLocation.Y + CurrentRadius) / (CurrentRadius * 2);
			FVector ClosestLocationOnArc = BezierCurve::GetLocation_1CP(Origin, ControlPoint, Destination, Alpha);
			
			if(ClosestLocationOnArc.DistSquaredXY(Player.ActorLocation) >= 500 * 500)
				continue;

			const bool bWithinArc = (Player.ActorLocation - ClosestLocationOnArc).GetSafeNormal().DotProduct(ActorForwardVector) <= 0;
			bWasPlayerWithinArc[Player] = bWithinArc;

			if(!bWithinArc || bWasWithinArc)
				continue;

			if(Player.ActorLocation.Z - ClosestLocationOnArc.Z > DamageWidth)
				continue;

			if(Player.ActorLocation.Z - ClosestLocationOnArc.Z < -200)
				continue;

			Player.DamagePlayerHealth(0.5);
		}
	}
};