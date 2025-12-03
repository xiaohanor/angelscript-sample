#if !RELEASE
namespace DevTogglesPinball
{
	const FHazeDevToggleBool DisableMagnetDroneLaunchedOffset;
};

struct FPinballLaunchedOffsetMove
{
	FVector Location;
	FQuat Rotation;
	bool bIsTeleport;
	TArray<FString> CallStack;
};
#endif

// I hate the MeshOffsetComponent lerp, so this is basically that but it doesn't just fully stop when activated
UCLASS(NotBlueprintable)
class UPinballMagnetDroneLaunchedOffsetComponent : UActorComponent
{
	default TickGroup = ETickingGroup::TG_LastDemotable;

	private AHazePlayerCharacter Player;

	FVector AccOffset;
	FVector OffsetPlane;
	float ReturnOffsetDuration;

#if !RELEASE
	private TArray<FPinballLaunchedOffsetMove> Moves;
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		auto RespawnComp = UPlayerRespawnComponent::Get(Player);
		RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnRespawn");

#if !RELEASE
		TEMPORAL_LOG(this, Owner, "PinballMagnetDroneLaunchedOffset");

		DevTogglesPinball::DisableMagnetDroneLaunchedOffset.MakeVisible();

		SceneComponent::BindOnSceneComponentMoved(Player.MeshOffsetComponent, FOnSceneComponentMoved(this, n"OnMeshOffsetComponentMoved"));
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		FTemporalLog PositionPageLog = TEMPORAL_LOG(Owner).Page("Launched Offset");

		PositionPageLog.DirectionalArrow("AccOffset", Pinball::GetBallPlayer().ActorLocation, AccOffset);

		for(int i = 0; i < Moves.Num(); i++)
		{
			FTemporalLog MoveSectionLog = PositionPageLog.Section(f"Move {i + 1}", i + 1);
			MoveSectionLog.Transform("Transform", FTransform(Moves[i].Rotation, Moves[i].Location), 500);
			MoveSectionLog.Value("Is Teleport", Moves[i].bIsTeleport);

			for(int j = 0; j < Moves[i].CallStack.Num(); j++)
			{
				MoveSectionLog.Value(f"Instigator {j + 1}", Moves[i].CallStack[j]);
			}
		}
		
		Moves.Reset();
#endif
	}

	void ApplyLaunchedOffset(
		FPinballLauncherLerpBackSettings LerpBackSettings,
		FVector LaunchLocation,
		FVector LaunchImpulse,
		FVector VisualLocation
	)
	{
		check(LerpBackSettings.bLerpBack);
		ReturnOffsetDuration = LerpBackSettings.GetLerpBackDuration();

		AccOffset = VisualLocation - LaunchLocation;
		
		if(LerpBackSettings.bOnlyLerpBackHorizontally)
		{
			OffsetPlane = LaunchImpulse.GetSafeNormal2D(FVector::ForwardVector);
			AccOffset = AccOffset.VectorPlaneProject(OffsetPlane);
		}
		else
		{
			OffsetPlane = FVector::ZeroVector;
		}

		Player.MeshOffsetComponent.SnapToLocation(this, VisualLocation);
	}

	bool HasOffset() const
	{
		return !AccOffset.IsNearlyZero();
	}

	void UpdateLaunchedOffset(float DeltaTime)
	{
		if(HasOffset())
		{
			if(ReturnOffsetDuration > 0)
				AccOffset = Math::VInterpTo(AccOffset, FVector::ZeroVector, DeltaTime, 1.0 / ReturnOffsetDuration);
			else
				AccOffset = FVector::ZeroVector;

			if(!OffsetPlane.IsNearlyZero())
				AccOffset = AccOffset.VectorPlaneProject(OffsetPlane);
			
			Player.MeshOffsetComponent.SnapToLocation(this, Player.ActorLocation + AccOffset);
		}
		else
		{
			Player.MeshOffsetComponent.SnapToLocation(this, Player.ActorLocation);
		}
	}

	UFUNCTION()
	private void OnMeshOffsetComponentMoved(USceneComponent MovedComponent, bool bIsTeleport)
	{
#if !RELEASE
		FPinballLaunchedOffsetMove Move;
		Move.Location = MovedComponent.WorldLocation;
		Move.Rotation = MovedComponent.ComponentQuat;
		Move.bIsTeleport = bIsTeleport;
		Move.CallStack = GetAngelscriptCallstack();

		// Remove self, event and actor from the callstack
		Move.CallStack.RemoveAt(0);
		Move.CallStack.RemoveAt(0);
		Move.CallStack.RemoveAt(0);

		if(Move.CallStack.IsEmpty())
			return;

		Moves.Add(Move);
#endif
	}

	void Reset()
	{
		AccOffset = FVector::ZeroVector;
		OffsetPlane = FVector::ZeroVector;
		ReturnOffsetDuration = 0;
		Player.MeshOffsetComponent.ClearOffset(this);
	}

	UFUNCTION()
	private void OnRespawn(AHazePlayerCharacter RespawnedPlayer)
	{
		Reset();
	}

};