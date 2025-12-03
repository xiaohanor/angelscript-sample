event void FTeamLazyTriggerShapeOverlap(AHazeActor Actor);

class UTeamLazyTriggerShapeComponent : UHazeEditorRenderedComponent
{
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "TriggerFor")
	FName TeamName = NAME_None;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Shape", Meta = (ShowOnlyInnerProperties))
	FHazeShapeSettings Shape;
	default Shape.Type = EHazeShapeType::Box;
	default Shape.BoxExtents = FVector(200.0, 200.0, 200.0);
	default Shape.SphereRadius = 200.0;
	default Shape.CapsuleRadius = 100.0;
	default Shape.CapsuleHalfHeight = 200.0;

	UPROPERTY(AdvancedDisplay, Category = "Precision")
	float NearbyThreshold = 2000.0;

	UPROPERTY(AdvancedDisplay, EditInstanceOnly, Category = "Precision")
	int NearbyPrecision = 1;

	UPROPERTY(AdvancedDisplay, EditInstanceOnly, Category = "Precision")
	int EnterPrecision = 5;

	UPROPERTY(AdvancedDisplay, EditInstanceOnly, Category = "Precision")
	int ExitPrecision = 5;

	// Whether to check if an nearby actor will teleport past the trigger when moving at high speed.
	UPROPERTY(AdvancedDisplay, EditAnywhere, Category = "Precision")
	bool bCheckOvershooting = false;

	// Whether the trigger should ignore networking and only trigger locally
    UPROPERTY(AdvancedDisplay, BlueprintReadOnly, EditAnywhere, Category = "Networking")
	bool bTriggerLocally = true;

	// Visualizer setting
	UPROPERTY(EditAnywhere, Category = "Editor Rendering")
	bool bAlwaysShowShapeInEditor = true;

	// Visualizer setting
	UPROPERTY(EditAnywhere, Category = "Editor Rendering")
	float EditorLineThickness = 2.0;
	
	// Color when actor is selected
	FLinearColor VisualizeColor = FLinearColor::Green;

	// Color when actor is not selected
	FLinearColor VisualizeNotSelectedColor = FLinearColor::Green;

	FTeamLazyTriggerShapeOverlap OnEnter;
	FTeamLazyTriggerShapeOverlap OnExit;

	private UHazeTeam Team;

	private int EnteredIndex = 0;
	private TArray<AHazeActor> Entered;
	private int NearbyIndex = 0;
	private TArray<AHazeActor> Nearby;
	private int MemberIndex = 0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		// Some shapes do not play well with scaling, so fix world scale at 1,1,1 and change extents instead
		if (!WorldScale.IsWithinDist(FVector::OneVector, KINDA_SMALL_NUMBER))
		{
			float SphereScale = WorldScale.Max;
			if (Math::IsNearlyEqual(SphereScale, 1.0))
				SphereScale = WorldScale.Min;
			Shape.SphereRadius = Math::Max(50.0, SphereScale * Shape.SphereRadius);

			float CapsuleRadiusScale = Math::Max(WorldScale.X, WorldScale.Y);
			if (Math::IsNearlyEqual(CapsuleRadiusScale, 1.0))
				CapsuleRadiusScale = Math::Min(WorldScale.X, WorldScale.Y);
			Shape.CapsuleRadius = Math::Max(25.0, CapsuleRadiusScale * Shape.CapsuleRadius);
			Shape.CapsuleHalfHeight = Math::Max(50.0, WorldScale.Z * Shape.CapsuleHalfHeight);

			Shape.BoxExtents.X = Math::Max(50.0, WorldScale.X * Shape.BoxExtents.X);
			Shape.BoxExtents.Y = Math::Max(50.0, WorldScale.Y * Shape.BoxExtents.Y);
			Shape.BoxExtents.Z = Math::Max(50.0, WorldScale.Z * Shape.BoxExtents.Z);
		}
		WorldScale3D = FVector::OneVector;

		// So we won't break scaling by relative rotation, we don't allow any
		WorldRotation = Owner.ActorRotation;

		// Let UTeamLazyTriggerShapeComponentVisualizer handle rendering for when selected.
		bRenderWhileSelected = false;
	}

	bool HasMembersNearby() const
	{
		return (Entered.Num() > 0) || (Nearby.Num() > 0);
	}

	void Update(float DeltaTime)
	{	
		float ShapeRadius = Shape.EncapsulatingSphereRadius;

		if (Team == nullptr)
			Team = HazeTeam::GetTeam(TeamName);

		TArray<AHazeActor> Members;
		if (Team != nullptr)
			Members = Team.GetMembers();

		if (Members.Num() == 0)
		{
			Nearby.Empty(Nearby.Num());
		}
		else
		{
			// Check if we should move a number of members into nearbys each update						
			int NumMembersChecked = Math::Min(NearbyPrecision, Members.Num());
			for (int i = 0; i < NumMembersChecked; i++) // int i just limits the number of checks, not used for accessing array elements.
			{
				if (!Members.IsValidIndex(MemberIndex))
					MemberIndex = 0;
				if (IsNearby(Members[MemberIndex], ShapeRadius + NearbyThreshold))
					Nearby.AddUnique(Members[MemberIndex]); // AddUnique since it might already be nearby
				MemberIndex++;
			}
		}

		// Check status of some nearby actors each update
		TArray<AHazeActor> NewlyEntered;
		int NumNearbyChecked = Math::Min(EnterPrecision, Nearby.Num());
		TArray<AHazeActor> NearbyRemoved;
		for (int i = 0; i < NumNearbyChecked; i++)
		{
			AHazeActor Actor = Nearby[(NearbyIndex + i) % Nearby.Num()];
			if (!bTriggerLocally && !Actor.HasControl())
				continue;

			if (!IsNearby(Actor, ShapeRadius + NearbyThreshold * 1.1))
			{
				NearbyRemoved.Add(Actor);
			}
			else if (HasEntered(Actor, Members))
			{
				NearbyRemoved.Add(Actor);
				NewlyEntered.Add(Actor); 
			}
			else if (bCheckOvershooting && IsOvershooting(Actor, Members, DeltaTime))
			{
				NearbyRemoved.Add(Actor);
				NewlyEntered.Add(Actor);
			}
		}
		// Remove those that either entered or are no longer nearby
		for (AHazeActor Actor : NearbyRemoved)
		{
			// Would be nice to store indices and use RemoveAtSwap instead, but then we'd still need to 
			// check the list once to sort it and we usually remove at most one item each update.
			Nearby.RemoveSingleSwap(Actor);
		}
		// Update index to start checking at next update
		if (Nearby.Num() > 0)
			NearbyIndex = (NearbyIndex + NumNearbyChecked - NearbyRemoved.Num()) % Nearby.Num();

		// Check if some previously entered actors have left 
		TArray<AHazeActor> NewlyExited;
		int NumEnteredChecked = Math::Min(ExitPrecision, Entered.Num());
		for (int i = 0; i < NumEnteredChecked; i++)
		{
			int iEntered = (EnteredIndex + i) % Entered.Num();

			AHazeActor Actor = Entered[iEntered];
			if (!bTriggerLocally && !Actor.HasControl())
				continue;

			if (HasLeft(Actor, Members, ShapeRadius))
				NewlyExited.Add(Actor);
		}

		// Update actual entered list late to ignore side effects until next update
		// E.g. when broadcasting events actor can change team or teleport.
		if (bTriggerLocally)
		{
			for (AHazeActor Actor : NewlyExited)
			{
				Entered.RemoveSingleSwap(Actor);
				OnExit.Broadcast(Actor);
			}
		}
		else
		{
			for (AHazeActor Actor : NewlyExited)
			{
				Entered.RemoveSingleSwap(Actor);
				check(Actor.HasControl(), "NewlyExited Actor does not have control! This should have been handled in NumEnteredChecked loop above.");
				CrumbOnExit(Actor);
			}
		}

		Entered.Append(NewlyEntered);
		
		// Trigger OnEnter
		if (bTriggerLocally)
		{
			for (AHazeActor Actor : NewlyEntered)
			{
				OnEnter.Broadcast(Actor);
			}
		}
		else
		{
			for (AHazeActor Actor : NewlyEntered)
			{
				check(Actor.HasControl(), "NewlyEntered Actor does not have control! This should have been handled in NumNearbyChecked loop above.");
				CrumbOnEnter(Actor);
			}
		}

		// Update index to start checking at next update
		if (Entered.Num() > 0)
			EnteredIndex = (EnteredIndex + NumEnteredChecked - NewlyExited.Num()) % Entered.Num();

#if EDITOR
		//bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugShape(Shape.CollisionShape, WorldLocation, WorldRotation, VisualizeColor, 5.0, DeltaTime);
			for (auto Near : Nearby)
				Debug::DrawDebugLine(WorldLocation, Near.ActorCenterLocation, FLinearColor::Yellow, 5.0, DeltaTime);
			for (auto In : Entered)
				Debug::DrawDebugLine(WorldLocation, In.ActorCenterLocation, FLinearColor::Green, 7.0, DeltaTime);
		}
#endif		
	}

	private bool IsNearby(AHazeActor Actor, float Range) const
	{
		if (!IsValid(Actor)) 
			return false;
		if (!Actor.ActorLocation.IsWithinDist(WorldLocation, Range))
			return false;
		if (Entered.Contains(Actor))
			return false;
		return true;
	}

	private bool HasEntered(AHazeActor Actor, TArray<AHazeActor> Members)
	{
		if (!Members.Contains(Actor))
			return false;
		if (!Shape.IsPointInside(WorldTransform, Actor.ActorLocation))
			return false;
		return true;
	}

	private bool HasLeft(AHazeActor Actor, TArray<AHazeActor> Members, float _BoundsRadius)
	{
		if (!IsValid(Actor))
			return true; 
		if (!Actor.ActorLocation.IsWithinDist(WorldLocation, _BoundsRadius))
			return true;
		if (!Members.Contains(Actor))
			return true;
		if (!Shape.IsPointInside(WorldTransform, Actor.ActorLocation))
			return true;
		return false;
	}

	// Note that this assumes that the velocity will not change direction.
	// Note also that overshoot may be overlooked if EnterPrecision is lower than number of Nearby Actors.
	// Finally note that this will trigger OnEnter before actually entering the trigger.
	private bool IsOvershooting(AHazeActor Actor, TArray<AHazeActor> Members, float DeltaTime)
	{
		check(Shape.Type == EHazeShapeType::Box, "IsOvershooting is currently only implemented for box shape.");

		if (!Members.Contains(Actor)) // Has already entered the shape
			return false;
		
		FVector MoveDelta = Actor.ActorVelocity * DeltaTime;
#if EDITOR
		MoveDelta *= Time::WorldTimeDilation;
#endif
		auto Box = FBox::BuildAABB(WorldTransform.Location, Shape.BoxExtents);
		if (!Math::LineBoxIntersection(Box, Actor.ActorLocation, Actor.ActorLocation + MoveDelta)) // Will not pass through volume
			return false;
		if (Shape.IsPointInside(WorldTransform, Actor.ActorLocation + MoveDelta)) // Not overshooting, will be handled by HasEntered-check in next tick.
			return false;

		return true;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnEnter(AHazeActor Actor)
	{
		Entered.AddUnique(Actor);
		OnEnter.Broadcast(Actor);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnExit(AHazeActor Actor)
	{
		Entered.RemoveSingleSwap(Actor);
		OnExit.Broadcast(Actor);
	}
	
	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
#if EDITOR
		if(!bAlwaysShowShapeInEditor)
			return;

		SetActorHitProxy();
		DrawWireShapeSettings(Shape, WorldLocation, ComponentQuat, VisualizeNotSelectedColor, EditorLineThickness, false);
#endif
	}
}
