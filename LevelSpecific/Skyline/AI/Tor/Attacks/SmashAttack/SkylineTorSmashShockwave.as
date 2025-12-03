struct FSkylineTorSmashShockwaveNode
{
	UPROPERTY()
	FVector StartLocation;
	UPROPERTY()
	FVector EndLocation;
	UPROPERTY()
	FVector EndedStartLocation;
	UPROPERTY()
	FVector EndedEndLocation;
	UPROPERTY()
	bool Ended;
}

enum ESkylineTorSmashShockwaveType
{
	Default,
	Wave
}

struct FSkylineTorSmashShockwaveWaveData
{
	FVector Direction;
	float Height;
	float Timer;

	FSkylineTorSmashShockwaveWaveData(FVector _Direction, float _Timer)
	{
		Direction = _Direction;
		Timer = _Timer;
	}
}

class ASkylineTorSmashShockwave : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	int NodeCount = 32;

	UPROPERTY()
	TArray<FSkylineTorSmashShockwaveNode> Nodes;

	UPROPERTY()
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	AHazeActor Owner;
	USkylineTorSettings TorSettings;
	private float CurrentRadius = 0;
	TArray<AHazeActor> HitTargets;
	FHazeAcceleratedFloat Speed;
	float MaxSpeed;
	float Duration = 15;

	ESkylineTorSmashShockwaveType Type;
	TArray<FSkylineTorSmashShockwaveWaveData> WaveData;
	float WaveHeight = 300;
	float WaveHeightAlpha;
	bool bWaveUp;
	bool bFade;

	UFUNCTION(BlueprintPure)
	float GetCurrentRadius() const
	{
		return CurrentRadius;
	}

	UFUNCTION(BlueprintPure)
	TArray<FVector> GetActiveNodeStartLocations(const FVector Offset = FVector::ZeroVector) const
	{
		TArray<FVector> StartLocations;
		StartLocations.Reserve(Nodes.Num()+1);

		if(Nodes.Num() <= 0)
			return StartLocations;

		for(int i = 0; i < Nodes.Num(); i++)
		{
			auto& NodeIter = Nodes[i];
			StartLocations.Add(NodeIter.StartLocation + Offset);
			// Debug::DrawDebugPoint(StartLocations.Last(), 20, FLinearColor::Green);
		}

		// close the loop.
		StartLocations.Add(Nodes[0].StartLocation + Offset);
		StartLocations.Add(Nodes[1].StartLocation + Offset);

		return StartLocations;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TorSettings = USkylineTorSettings::GetSettings(Owner);
		CurrentRadius = TorSettings.SmashMinimumRadius;
		
		for(int i = 0; i < NodeCount; i++)
			Nodes.Add(FSkylineTorSmashShockwaveNode());

		USkylineTorSmashShockwaveEventHandler::Trigger_OnShockwaveStart(this, FSkylineTorSmashShockwaveEventHandlerData(Duration));

		Speed.SnapTo(TorSettings.SmashExpansionBaseSpeed / 4);

		float SegmentAngle = (360.0 / NodeCount);
		int NodeSegment = Math::IntegerDivisionTrunc(NodeCount, 3);
		WaveData.Add(FSkylineTorSmashShockwaveWaveData(FVector::ForwardVector, 0));
		WaveData.Add(FSkylineTorSmashShockwaveWaveData(FVector::ForwardVector.RotateAngleAxis(SegmentAngle * NodeSegment, FVector::UpVector), 1));
		WaveData.Add(FSkylineTorSmashShockwaveWaveData(FVector::ForwardVector.RotateAngleAxis(SegmentAngle * NodeSegment * 2, FVector::UpVector), 2));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Speed.AccelerateTo(MaxSpeed, 3, DeltaTime);
		CurrentRadius += Speed.Value * DeltaTime;
		// Debug::DrawDebugCylinder(ActorLocation, ActorLocation, CurrentRadius, 32, FLinearColor::Yellow, TorSettings.SmashDamageWidth * 2);

		for(int i = 0; i < NodeCount; i++)
		{			
			float StartAngle = (360.0 / NodeCount) * i;
			FVector StartDir = FVector::ForwardVector.RotateAngleAxis(StartAngle, FVector::UpVector);

			int EndIndex = i == NodeCount-1 ? 0 : i+1;
			float EndAngle = (360.0 / NodeCount) * EndIndex;
			FVector EndDir = FVector::ForwardVector.RotateAngleAxis(EndAngle, FVector::UpVector);

			FSkylineTorSmashShockwaveNode& Node = Nodes[i];

			FVector StartLocation = ActorLocation + StartDir * CurrentRadius;
			FVector EndLocation = ActorLocation + EndDir * CurrentRadius;

			FVector StartNavLocation;
			FVector EndNavLocation;

			if(!Node.Ended)
			{
				if(Pathfinding::FindNavmeshLocation(StartLocation, 50, 500, StartNavLocation))
					StartLocation = StartNavLocation + FVector::UpVector * (TorSettings.SmashDamageWidth / 2);
				else 
					Node.Ended = true;

				if(Pathfinding::FindNavmeshLocation(EndLocation, 50, 500, EndNavLocation))
					EndLocation = EndNavLocation + FVector::UpVector * (TorSettings.SmashDamageWidth / 2);
				else
					Node.Ended = true;
			}

			// Do not make this an "else" with the previous if statement, we want to check this right after setting Ended to true
			if(Node.Ended)
			{
				StartLocation.Z = Node.EndedStartLocation.Z;
				EndLocation.Z = Node.EndedEndLocation.Z;
			}
			else
			{
				Node.EndedStartLocation = StartLocation;
				Node.EndedEndLocation = EndLocation;
			}
			
			if(Type == ESkylineTorSmashShockwaveType::Wave)
			{
				for(int WaveIndex = 0; WaveIndex < WaveData.Num(); WaveIndex++)
				{
					// WaveAngles[WaveIndex] += 4 * DeltaTime;
					FSkylineTorSmashShockwaveWaveData& WaveItem = WaveData[WaveIndex];
					// if(WaveAngle > 360)
					// 	WaveAngles[WaveIndex] = 0;

					WaveItem.Timer += DeltaTime * 0.5;
					float SectionHeight = (WaveHeight / 4);

					float Modifier = 1.5;
					if(bWaveUp)
					{
						WaveHeightAlpha += DeltaTime * 0.1 * Modifier;
						bWaveUp = WaveHeightAlpha < 1;
					}
					else
					{
						WaveHeightAlpha -= DeltaTime * 0.015 * Modifier;
						bWaveUp = WaveHeightAlpha < 0;
					}

					float Height = SectionHeight + (WaveHeightAlpha * SectionHeight * 3);

					
					float StartFactor = Math::EaseInOut(0, 1, Math::Clamp(1 - (Math::Abs(StartDir.GetAngleDegreesTo(WaveItem.Direction))) / 35, 0, 1), 3);
					StartLocation.Z += Height * StartFactor;

					float EndFactor = Math::EaseInOut(0, 1, Math::Clamp(1 - (Math::Abs(EndDir.GetAngleDegreesTo(WaveItem.Direction))) / 35, 0, 1), 1);
					EndLocation.Z += Height * EndFactor;
				}
			}

			Node.StartLocation = StartLocation;
			Node.EndLocation = EndLocation;
		}

		// for(FSkylineTorSmashShockwaveNode Node : Nodes)
		// {
		// 	if(!Node.Ended)
		// 		Debug::DrawDebugLine(Node.StartLocation, Node.EndLocation, FLinearColor::Yellow, Thickness = TorSettings.SmashDamageWidth * 2);
		// }

		for (AHazePlayerCharacter CurPlayer : Game::GetPlayers())
		{
			if(HitTargets.Contains(CurPlayer))
				continue;

			for(FSkylineTorSmashShockwaveNode Node : Nodes)
			{
				FCollisionShape Shape = FCollisionShape();
				Shape.SetCapsule(TorSettings.SmashDamageWidth, Node.StartLocation.Distance(Node.EndLocation));

				FVector CenterLocation = (Node.StartLocation + Node.EndLocation) / 2;
				if(CenterLocation.Distance(CurPlayer.ActorCenterLocation) > 500)
					continue;

				FTransform Transform;
				Transform.SetLocation(CenterLocation);
				Transform.SetRotation((Node.StartLocation - Node.EndLocation).Rotation() + FRotator(90, 0, 0));

				bool bDamagePlayer = !bFade && Overlap::QueryShapeOverlap(CurPlayer.CapsuleComponent.GetCollisionShape(), CurPlayer.CapsuleComponent.WorldTransform, Shape, Transform);
				if (bDamagePlayer && CurPlayer.HasControl())
				{
					UGravityBladeCombatUserComponent CombatComp = UGravityBladeCombatUserComponent::Get(CurPlayer);
					if(CombatComp != nullptr)
					{
						if(CombatComp.ActiveAttackData.IsRushAttack())
							continue;
					}

					CurPlayer.DamagePlayerHealth(0.5, DamageEffect = DamageEffect, DeathEffect = DeathEffect);

					FStumble Stumble;
					FVector Dir = (CurPlayer.ActorLocation - Owner.ActorLocation).GetNormalized2DWithFallback(-CurPlayer.ActorForwardVector);
					Stumble.Move = Dir * 250;
					Stumble.Duration = 0.5;
					CurPlayer.ApplyStumble(Stumble);
					
					HitTargets.Add(CurPlayer);
					break;
				}
			}
		}

		if(!bFade && CurrentRadius > TorSettings.SmashMaximumRadius - 500)
		{
			bFade = true;
			USkylineTorSmashShockwaveEventHandler::Trigger_OnShockwaveStartFade(this, FSkylineTorSmashShockwaveEventHandlerData(0.5));
		}

		if(CurrentRadius > TorSettings.SmashMaximumRadius)
		{
			USkylineTorSmashShockwaveEventHandler::Trigger_OnShockwaveStop(this);
			AddActorDisable(this);
		}
	}
}