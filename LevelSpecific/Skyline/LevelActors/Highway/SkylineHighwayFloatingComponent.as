struct FSkylineHighwayFloatingData
{
	UPROPERTY()
	bool bRotation = false;
	
	UPROPERTY()
	FVector Axis;

	UPROPERTY()
	float Rate = 1.0;

	UPROPERTY()
	float Offset = 0.0;
}

struct FSkylineHighwayFloatingImpostor
{
	UPrimitiveComponent Component;
	FTransform OriginalRelativeTransform;
	FTransform OriginalTransformToFloating;
}

const FConsoleVariable CVar_SkylineUseFloatingImpostors("SkylineHighway.UseFloatingImpostors", true);
const FConsoleVariable CVar_SkylineBlockCollisionFarAway("SkylineHighway.BlockCollisionFarAway", true);
const FConsoleVariable CVar_SkylineFloatingImpostorDistance("SkylineHighway.FloatingImpostorDistance", 8000.0);

class USkylineHighwayFloatingComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	TArray<FSkylineHighwayFloatingData> FloatingData;

	UPROPERTY(EditAnywhere)
	bool bReattachChildrenToThis = true;

	UPROPERTY(EditAnywhere)
	bool bWorldSpace = false;

	UPROPERTY(EditAnywhere)
	bool bUseLocationOffset = true;

	UPROPERTY(EditAnywhere)
	float BlendInTime = 2.0;

	UPROPERTY(EditAnywhere)
	float DistanceLocationMultiplier = 4.0;

	UPROPERTY(EditAnywhere)
	float DistanceRotationMultiplier = 2.0;

	UPROPERTY(EditAnywhere)
	float MinMultiplierDistance = 2000.0;

	UPROPERTY(EditAnywhere)
	float MaxMultiplierDistance = 6000.0;

	UPROPERTY(EditAnywhere)
	bool bUseImpostorMeshesAtDistance = true;
	UPROPERTY(EditAnywhere)
	bool bDisableCollisionAtDistance = true;

	UPROPERTY(EditAnywhere)
	float MaximumFloatingDistance = 25000;
	UPROPERTY(EditAnywhere)
	float FloatingDistanceBlendRange = 3000;

	FHazeAcceleratedFloat AcceleratedFloat;
	FHazeAcceleratedFloat AcceleratedDistanceMultiplier;

	float LocationOffset = 0.0;

	float BlendAlpha = 1.0;

	private TArray<FSkylineHighwayFloatingImpostor> Impostors;
	private bool bUsingImpostors = false;
	private bool bUsingCollision = true;
	private TArray<AActor> AttachedActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcceleratedFloat.SnapTo(BlendAlpha);

		if (bReattachChildrenToThis)
		{
			Owner.GetAttachedActors(AttachedActors);
			for (auto AttachedActor : AttachedActors)
				AttachedActor.AttachToComponent(this, AttachmentRule = EAttachmentRule::KeepRelative);
		}
	
		if (bUseLocationOffset)
			LocationOffset = WorldLocation.Size();

		if (bUseImpostorMeshesAtDistance)
		{
			TArray<UPrimitiveComponent> AttachedPrimitives;
			GetChildrenComponentsByClass(UPrimitiveComponent, true, AttachedPrimitives);

			FTransform FloatingTransform = GetWorldTransform();

			for (auto Primitive : AttachedPrimitives)
			{
				bool bUseAsImpostor = Primitive.IsVisible() && !Primitive.bHiddenInGame && Primitive.HasTag(n"UseAsFloatingImpostor");
				if (!bUseAsImpostor)
					continue;

				FSkylineHighwayFloatingImpostor ImpostorData;
				ImpostorData.Component = Primitive;
				ImpostorData.OriginalRelativeTransform = Primitive.GetRelativeTransform();
				ImpostorData.OriginalTransformToFloating = FTransform::GetRelative(FloatingTransform, Primitive.GetWorldTransform());

				Impostors.Add(ImpostorData);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// float StartTime = Time::PlatformTimeSeconds;

		AcceleratedFloat.AccelerateTo(BlendAlpha, BlendInTime, DeltaSeconds);

		FTransform Transform;

		float DistanceToClosestPlayer = Game::GetDistanceFromLocationToClosestPlayer(WorldLocation);
		float MultiplierTarget = Math::GetMappedRangeValueClamped(FVector2D(MinMultiplierDistance, MaxMultiplierDistance), FVector2D(0.0, 1.0), DistanceToClosestPlayer);

		AcceleratedDistanceMultiplier.AccelerateTo(MultiplierTarget, 2.0, DeltaSeconds);

		for (auto Data : FloatingData)
		{	
			if (Data.bRotation)
				Transform.Rotation = Transform.Rotation * FQuat(Data.Axis.GetSafeNormal(), Math::Sin(((Time::GameTimeSeconds + LocationOffset) * Data.Rate) + Data.Offset) * Math::DegreesToRadians(Data.Axis.Size()) * Math::Lerp(1.0, DistanceRotationMultiplier, AcceleratedDistanceMultiplier.Value));
			else
				Transform.Location = Transform.Location + Data.Axis * Math::Sin(((Time::GameTimeSeconds + LocationOffset) * Data.Rate) + Data.Offset) * Math::Lerp(1.0, DistanceLocationMultiplier, AcceleratedDistanceMultiplier.Value);
		}

		float DistanceToPlayers = Math::Min(
			Game::Mio.GetDistanceTo(Owner),
			Game::Zoe.GetDistanceTo(Owner),
		);

		if (DistanceToPlayers < 6000 || !CVar_SkylineBlockCollisionFarAway.GetBool() || !bDisableCollisionAtDistance)
			SetUseCollision(true);
		else
			SetUseCollision(false);

		float TargetBlend = Math::GetMappedRangeValueClamped(
			FVector2D(MaximumFloatingDistance - FloatingDistanceBlendRange, MaximumFloatingDistance),
			FVector2D(1, 0),
			DistanceToPlayers,
		);

		if (DistanceToPlayers < CVar_SkylineFloatingImpostorDistance.GetFloat() || !bUseImpostorMeshesAtDistance || !CVar_SkylineUseFloatingImpostors.GetBool())
		{
			SetUseImpostors(false);
			RelativeTransform = LerpTransform(FTransform::Identity, Transform, AcceleratedFloat.Value * TargetBlend);
		}
		else
		{
			SetUseImpostors(true);
			UpdateImpostorTransforms(LerpTransform(FTransform::Identity, Transform, AcceleratedFloat.Value * TargetBlend));
		}

		// float EndTime = Time::PlatformTimeSeconds;
		// PrintToScreen(f"{Owner.Name} took {(EndTime - StartTime) * 1000 :.4} ms {bUsingImpostors=}");
	}

	void SetUseCollision(bool bUseCollision)
	{
		if (bUseCollision == bUsingCollision)
			return;
		bUsingCollision = bUseCollision;

		if (bUsingCollision)
		{
			Owner.RemoveActorCollisionBlock(this);
			for (auto Attach : AttachedActors)
				Attach.RemoveActorCollisionBlock(this);
		}
		else
		{
			Owner.AddActorCollisionBlock(this);
			for (auto Attach : AttachedActors)
				Attach.AddActorCollisionBlock(this);
		}
	}

	void SetUseImpostors(bool bUseImpostor)
	{
		if (bUseImpostor == bUsingImpostors)
			return;

		bUsingImpostors = bUseImpostor;
		if (bUsingImpostors)
		{
			for (auto ImpostorData : Impostors)
			{
				if (!IsValid(ImpostorData.Component))
					continue;

				ImpostorData.Component.SetAbsolute(true, true, true);
			}
		}
		else
		{
			for (auto ImpostorData : Impostors)
			{
				if (!IsValid(ImpostorData.Component))
					continue;

				ImpostorData.Component.SetAbsolute(false, false, false);
				ImpostorData.Component.SetRelativeTransform(ImpostorData.OriginalRelativeTransform);
			}
		}
	}

	void UpdateImpostorTransforms(FTransform FloatingRelativeTransform)
	{
		FTransform FloatingWorldTransform = FTransform::ApplyRelative(AttachParent.WorldTransform, FloatingRelativeTransform);

		for (auto ImpostorData : Impostors)
		{
			if (!IsValid(ImpostorData.Component))
				continue;

			ImpostorData.Component.SetWorldTransform(
				FTransform::ApplyRelative(FloatingWorldTransform, ImpostorData.OriginalTransformToFloating)
			);
		}
	}

	FTransform LerpTransform(FTransform A, FTransform B, float Alpha)
	{
		FTransform Transform;
		Transform.Location = Math::Lerp(A.Location, B.Location, Alpha);
		Transform.Rotation = FQuat::Slerp(A.Rotation, B.Rotation, Alpha);
		Transform.Scale3D = Math::Lerp(A.Scale3D, B.Scale3D, Alpha);
		
		return Transform;
	}
}