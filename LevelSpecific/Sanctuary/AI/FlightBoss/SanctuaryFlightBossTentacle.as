class USanctuaryFlightBossTentacleSettings : UHazeComposableSettings 
{
	UPROPERTY(Category = "Tentacle")
	int NumTentacleSegments = 100;

	UPROPERTY(Category = "Tentacle")
	int NumSplinePoints = 5;

	UPROPERTY(Category = "Tentacle")
	float IdleLength = 3000.0;

	// Switch target after this number of attacks
	UPROPERTY(Category = "Tentacle")
	float SwitchTargetCount = 1;

	// Pause for this many seconds when switching target
	UPROPERTY(Category = "Tentacle")
	float SwitchTargetPauseDuration = 5.0;

	UPROPERTY(Category = "Tentacle")
	FLinearColor DebugColor = FLinearColor::Purple;

	UPROPERTY(Category = "Tentacle")
	float Width = 5.0;

	UPROPERTY(Category = "Tentacle")
	float TaperFactor = 0.995;

	UPROPERTY(Category = "Stab")
	float StabDuration = 3.0;

	UPROPERTY(Category = "Stab")
	float StabCooldown = 5.0;

	UPROPERTY(Category = "Slash")
	float SlashDuration = 5.0;

	UPROPERTY(Category = "Slash")
	float SlashCooldown = 5.0;

	UPROPERTY(Category = "Slash")
	float SlashHeight = 5000.0;

	UPROPERTY(Category = "Sweep")
	float SweepDuration = 5.0;

	UPROPERTY(Category = "Sweep")
	float SweepCooldown = 8.0;

	UPROPERTY(Category = "Sweep")
	float SweepStartAngle = 90.0;

	UPROPERTY(Category = "Sweep")
	float SweepAngularSpeed = 30.0;
}

struct FSanctuaryFlightBossTentacleMovement
{
	FHazeAcceleratedVector Location;
	FVector TargetLocation;
}

class USanctuaryFlightBossTentacleComponent : USceneComponent
{
	UPROPERTY()
	TSubclassOf<USanctuaryFlightBossTentacleSegment> SegmentClass;

	USanctuaryFlightBossTentacleSettings Settings;
	TArray<FSanctuaryFlightBossTentacleMovement> Points;
	TArray<USanctuaryFlightBossTentacleSegment> Segments;
	int NumAttacksAgainstTarget = 0;
	TInstigated<float> Acceleration; 
	default Acceleration.DefaultValue = 0.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = USanctuaryFlightBossTentacleSettings::GetSettings(Cast<AHazeActor>(Owner));
		Points.SetNum(Settings.NumSplinePoints);
		for (int i = 0; i < Settings.NumSplinePoints; i++)
		{
			Points[i].TargetLocation = GetIdleCenterLocation(i);
			Points[i].Location.SnapTo(Points[i].TargetLocation);	
		}

		for (int i = 0; i < Settings.NumTentacleSegments; i++)
		{
			Segments.Add(Cast<USanctuaryFlightBossTentacleSegment>(Owner.CreateComponent(SegmentClass)));
		}
	}

	FVector GetIdleCenterLocation(int SplineIndex) const
	{
		float Length = Settings.IdleLength * 0.01 + Settings.IdleLength * 0.99 * Math::Square(SplineIndex / Math::Max(1.0, float(Settings.NumSplinePoints - 1)));
		return WorldLocation + WorldRotation.RotateVector(FVector(Length, 0.0, 0.0));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Settings.NumSplinePoints != Points.Num())
		{
			int PrevSize = Points.Num();
			Points.SetNum(Settings.NumSplinePoints);
			for (int i = PrevSize; i < Settings.NumSplinePoints; i++)
			{
				Points[i].TargetLocation = GetIdleCenterLocation(i);
				Points[i].Location.SnapTo(Points[i].TargetLocation);	
			}
		}

		// Generate spline from points	
		FHazeRuntimeSpline Spline;
		for (FSanctuaryFlightBossTentacleMovement& Point : Points)
		{
			Point.Location.SpringTo(Point.TargetLocation, Acceleration.Get(), 0.5, DeltaTime);
			Spline.AddPoint(Point.Location.Value);
		}		

		TArray<FVector> SplineLocs; 
		Spline.GetLocations(SplineLocs, Settings.NumTentacleSegments);
		float Width = Settings.Width;
		float SegmentLength = Spline.Length / Settings.NumTentacleSegments;
		for (int i = 0; i < Settings.NumTentacleSegments; i++)
		{
			FVector Loc = SplineLocs[i + 1];
			FRotator Rot = Spline.GetDirectionAtDistance(SegmentLength * (i + 1)).Rotation();
			Segments[i].SetWorldLocationAndRotation(Loc, Rot);
			Segments[i].SetWorldScale3D(FVector(SegmentLength * 0.03, Width, Width));
			Width *= Settings.TaperFactor;
		}		

#if EDITOR
		//bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool)
		{
			float DebugRadius = 100.0;
			for (FSanctuaryFlightBossTentacleMovement Point : Points)
			{
				Debug::DrawDebugSphere(Point.Location.Value, DebugRadius, 4, FLinearColor::Yellow, 10.0);
				Debug::DrawDebugSphere(Point.TargetLocation, DebugRadius, 8, FLinearColor::Red, 10.0);
				Debug::DrawDebugLine(Point.TargetLocation, Point.Location.Value, FLinearColor::Red, 10.0);
				DebugRadius += 100.0;	
			}
		}
#endif
	}
}

class USanctuaryFlightBossIdleTentacleCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Tentacle");

	USanctuaryFlightBossComponent BossComp;
	USanctuaryFlightBossTentacleComponent Tentacle;
	USanctuaryFlightBossTentacleSettings TentacleSettings;

	float UpdateTentacleTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossComp = USanctuaryFlightBossComponent::Get(Owner);
		Tentacle = USanctuaryFlightBossTentacleComponent::Get(Owner);
		TentacleSettings = USanctuaryFlightBossTentacleSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BossComp.CurrentAttack == ESanctuaryFlightBossAttack::TentacleSweep)
			return false;
		if (BossComp.CurrentAttack == ESanctuaryFlightBossAttack::TentacleSlash)
			return false;
		if (BossComp.CurrentAttack == ESanctuaryFlightBossAttack::TentacleStab)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BossComp.CurrentAttack == ESanctuaryFlightBossAttack::TentacleSweep)
			return true;
		if (BossComp.CurrentAttack == ESanctuaryFlightBossAttack::TentacleSlash)
			return true;
		if (BossComp.CurrentAttack == ESanctuaryFlightBossAttack::TentacleStab)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds < UpdateTentacleTime)
			return;

		// Note that we never move first point
		int iPoint = Math::RandRange(1, Tentacle.Points.Num() - 1);

		FVector CurVel = Tentacle.Points[iPoint].Location.Velocity;
		FVector LocalOffsetDir; 
		if (CurVel.IsNearlyZero())
			LocalOffsetDir = Math::GetRandomPointOnCircle_YZ();
		else
			LocalOffsetDir = Math::GetRandomConeDirection(Tentacle.WorldRotation.UnrotateVector(-CurVel.GetSafeNormal()), PI * 0.1 * iPoint);
		float OffsetDist = iPoint * iPoint * Math::RandRange(50.0, 150.0);
		FVector Offset = Tentacle.WorldRotation.RotateVector(LocalOffsetDir * OffsetDist);
		Tentacle.Points[iPoint].TargetLocation = Tentacle.GetIdleCenterLocation(iPoint) + Offset;

		UpdateTentacleTime = Time::GameTimeSeconds + (5.0 / float(TentacleSettings.NumSplinePoints));
	}
}

UCLASS(Abstract)
class USanctuaryFlightBossTentacleSegment : UStaticMeshComponent
{
	default bCanEverAffectNavigation = false;
}
