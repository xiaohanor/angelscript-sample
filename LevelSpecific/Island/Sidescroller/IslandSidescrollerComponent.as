class UIslandSidescrollerComponent : UActorComponent
{
	access ExternalReadOnly = private, * (readonly);

	private bool bInSidescrollerMode = false;
	private AHazePlayerCharacter Player;
	private bool bIsInFullscreen = false;

	private TArray<AIslandSidescrollerEdgeCollisionActor> EdgeColliders;
	private const int AmountOfEdgeColliders = 3;
	private bool bEdgeCollidersEnabled = false;
	private bool bUseTopCollider = false;
	private float PlayerCapsuleRadius;

	access:ExternalReadOnly FTransform SidescrollerTransform;

	TArray<AActor> OneWayPlatforms;

	TArray<FInstigator> EdgeColliderBlockers;

	const float RespawnEdgeColliderDisableDuration = 1.0;
	const float InitialEdgeColliderDisableDuration = 1.0;
	UIslandTopDownComponent TopDownComp;
	TPerPlayer<UIslandSidescrollerComponent> SidescrollerComp;
	TPerPlayer<UPlayerMovementComponent> MoveComp;
	TPerPlayer<bool> CollisionEnabledForPlayer;
	TPerPlayer<bool> HasBeenGrounded;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CollisionEnabledForPlayer[0] = true;
		CollisionEnabledForPlayer[1] = true;

		Player = Cast<AHazePlayerCharacter>(Owner);
		for(AHazePlayerCharacter Current : Game::Players)
		{
			SidescrollerComp[Current] = UIslandSidescrollerComponent::GetOrCreate(Current);
			MoveComp[Current] = UPlayerMovementComponent::Get(Current);
		}

		// UPlayerRespawnComponent::GetOrCreate(Player).OnPlayerRespawned.AddUFunction(this, n"OnRespawned");
		// UPlayerRespawnComponent::GetOrCreate(Player.OtherPlayer).OnPlayerRespawned.AddUFunction(this, n"OnRespawned");
		TopDownComp = UIslandTopDownComponent::GetOrCreate(Player);
		PlayerCapsuleRadius = Player.CapsuleComponent.CapsuleRadius;
	}

	// UFUNCTION(NotBlueprintCallable)
	// private void OnRespawned(AHazePlayerCharacter RespawnedPlayer)
	// {
	// 	DisableEdgeColliders();
	// 	Timer::SetTimer(this, n"EnableEdgeColliders", RespawnEdgeColliderDisableDuration);
	// }

	void AddEdgeColliderBlocker(FInstigator Instigator)
	{
		EdgeColliderBlockers.AddUnique(Instigator);
	}

	void RemoveEdgeColliderBlocker(FInstigator Instigator)
	{
		EdgeColliderBlockers.RemoveSingleSwap(Instigator);
	}

	private bool IsEdgeColliderBlocked()
	{
		return EdgeColliderBlockers.Num() > 0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HandleEdgeColliders())
			EnableEdgeColliders();
		else
			DisableEdgeColliders();
	}

	bool IsInSidescrollerMode() const
	{
		return bInSidescrollerMode;
	}

	bool IsInFullscreen() const
	{
		return IsInSidescrollerMode() && bIsInFullscreen;
	}

	void EnterSidescrollerMode(AHazeActor SplineActor, bool bFullscreen = true, AHazeCameraActor InitialCamera = nullptr, float CameraBlendTime = 0.0, bool bTopCollider = true)
	{
		devCheck(!bInSidescrollerMode, "Tried to enter sidescroller mode when we already are in sidescroller mode.");
		Player.LockPlayerMovementToSpline(SplineActor, this, EInstigatePriority::Normal, FPlayerMovementSplineLockProperties());
		Player.ApplyAiming2DSplineConstraint(SplineActor, this);
		Player.ApplyGameplayPerspectiveMode(EPlayerMovementPerspectiveMode::SideScroller, this);

		FQuat ClosestRotation = Spline::GetGameplaySpline(SplineActor).GetClosestSplineWorldRotationToWorldLocation(Player.ActorLocation);
		FVector Forward = ClosestRotation.ForwardVector;
		if(Player.ActorForwardVector.DotProduct(Forward) < -KINDA_SMALL_NUMBER)
			Forward = -Forward;

		Player.ActorRotation = FRotator::MakeFromZX(Player.MovementWorldUp, Forward);

		if(InitialCamera != nullptr)
		{
			Player.ActivateCamera(InitialCamera, CameraBlendTime, this);
		}

		if(bFullscreen)
		{
			Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);

			if(EdgeColliders.Num() == 0)
				CreateAndDisableEdgeColliders();
		}

		bUseTopCollider = bTopCollider;
		bIsInFullscreen = bFullscreen;
		bInSidescrollerMode = true;
		SidescrollerTransform = Spline::GetGameplaySpline(SplineActor).GetWorldTransformAtSplineDistance(0.0);

		auto AnimLookAtComp = UHazeAnimPlayerLookAtComponent::Get(Player);
		if(AnimLookAtComp != nullptr)
			AnimLookAtComp.Disable(this);
	}

	void ExitSidescrollerMode()
	{
		devCheck(bInSidescrollerMode, "Tried to exit sidescroller when we haven't entered sidescroller mode.");
		Player.UnlockPlayerMovementFromSpline(this);
		Player.ClearAiming2DConstraint(this);
		Player.ClearGameplayPerspectiveMode(this);
		Player.DeactivateCameraByInstigator(this);

		if(bIsInFullscreen)
		{
			Player.ClearViewSizeOverride(this);
		}

		DisableEdgeColliders();

		bIsInFullscreen = false;
		bInSidescrollerMode = false;

		auto AnimLookAtComp = UHazeAnimPlayerLookAtComponent::Get(Player);
		if(AnimLookAtComp != nullptr)
			AnimLookAtComp.ClearDisabled(this);
	}

	private void CreateAndDisableEdgeColliders()
	{
		for(int i = 0; i < AmountOfEdgeColliders; i++)
		{
			EdgeColliders.Add(SpawnActor(AIslandSidescrollerEdgeCollisionActor));
			EdgeColliders[i].AddActorDisable(this);
			EdgeColliders[i].MakeNetworked(this, i);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void EnableEdgeColliders()
	{
		if(bEdgeCollidersEnabled)
			return;

		for(int i = 0; i < EdgeColliders.Num(); i++)
		{
			if(i == 2 && !bUseTopCollider)
				continue;

			EdgeColliders[i].RemoveActorDisable(this);
		}

		bEdgeCollidersEnabled = true;
	}

	UFUNCTION(NotBlueprintCallable)
	private void DisableEdgeColliders()
	{
		if(!bEdgeCollidersEnabled)
			return;

		for(int i = 0; i < EdgeColliders.Num(); i++)
		{
			EdgeColliders[i].AddActorDisable(this);
		}

		bEdgeCollidersEnabled = false;
	}

	private bool HandleEdgeColliders()
	{
		if(!bInSidescrollerMode)
			return false;

		if(!bIsInFullscreen)
			return false;

		if(IsEdgeColliderBlocked())
			return false;

		// if(Time::GameTimeSeconds < InitialEdgeColliderDisableDuration)
		// 	return false;

		// If we are in top down right now we don't want to use edge colliders until we leave top down.
		if(TopDownComp.IsInTopDownMode())
			return false;

		const float ColliderExtent = 100.0;

		FVector CenterPoint = GetWorldCenterOfScreen();
		FVector2D ScreenExtents = GetWorldExtentsOfScreen();

		FVector LeftColliderOrigin = CenterPoint - SidescrollerTransform.Rotation.ForwardVector * (ScreenExtents.X + ColliderExtent);
		FVector RightColliderOrigin = CenterPoint + SidescrollerTransform.Rotation.ForwardVector * (ScreenExtents.X + ColliderExtent);
		FVector TopColliderOrigin = CenterPoint + SidescrollerTransform.Rotation.UpVector * (ScreenExtents.Y + ColliderExtent);
		
		EdgeColliders[0].ActorLocation = LeftColliderOrigin - SidescrollerTransform.Rotation.RightVector * PlayerCapsuleRadius;
		EdgeColliders[0].ActorRotation = SidescrollerTransform.Rotator();
		EdgeColliders[0].BoxExtent = FVector(ColliderExtent, ColliderExtent, ScreenExtents.Y * 2.0); // Times 2 so you can't exit colliders to the left or right and be stuck outside

		EdgeColliders[1].ActorLocation = RightColliderOrigin + SidescrollerTransform.Rotation.RightVector * PlayerCapsuleRadius;
		EdgeColliders[1].ActorRotation = SidescrollerTransform.Rotator();
		EdgeColliders[1].BoxExtent = FVector(ColliderExtent, ColliderExtent, ScreenExtents.Y * 2.0); // Times 2 so you can't exit colliders to the left or right and be stuck outside

		if(bUseTopCollider)
		{
			EdgeColliders[2].ActorLocation = TopColliderOrigin;
			EdgeColliders[2].ActorRotation = SidescrollerTransform.Rotator();
			EdgeColliders[2].BoxExtent = FVector::ForwardVector * ScreenExtents.X + FVector::UpVector * ColliderExtent + FVector::RightVector * ColliderExtent;
		}

		for(AHazePlayerCharacter Current : Game::Players)
		{
			SetCollisionEnabledForPlayer(Current, IsPlayerOnScreen(Current, !CollisionEnabledForPlayer[Current]));
		}

		return true;
	}

	FVector2D GetWorldExtentsOfScreen() const
	{
		for(AHazePlayerCharacter Current : Game::Players)
		{
			if(!SidescrollerComp[Current].IsInFullscreen())
				continue;

			FVector Origin, Direction;
			SceneView::DeprojectScreenToWorld_Relative(Player, FVector2D(0.0, 0.0), Origin, Direction);
			FVector CenterPoint = GetWorldCenterOfScreen();

			const FPlane SidescrollerPlane = FPlane(SidescrollerTransform.Location, SidescrollerTransform.Rotation.RightVector);
			const FVector BottomLeftPoint = Math::RayPlaneIntersection(Origin, Direction, SidescrollerPlane);

			const float ScreenWorldHalfHeight = Math::Abs(BottomLeftPoint.Z - CenterPoint.Z);
			const float ScreenWorldHalfWidth = BottomLeftPoint.DistXY(CenterPoint);
			return FVector2D(ScreenWorldHalfWidth, ScreenWorldHalfHeight);
		}

		devError("Tried to get world extents of screen when no player is in fullscreen");
		return FVector2D();
	}

	FVector GetWorldCenterOfScreen() const
	{
		return ScreenPositionToWorldPosition(FVector2D(0.5, 0.5));
	}

	FVector ScreenPositionToWorldPosition(FVector2D ScreenPosition) const
	{
		for(AHazePlayerCharacter Current : Game::Players)
		{
			if(!SidescrollerComp[Current].IsInFullscreen())
				continue;

			FVector CenterOrigin, CenterDirection;
			SceneView::DeprojectScreenToWorld_Relative(Player, ScreenPosition, CenterOrigin, CenterDirection);

			const FPlane SidescrollerPlane = FPlane(SidescrollerTransform.Location, SidescrollerTransform.Rotation.RightVector);
			return Math::RayPlaneIntersection(CenterOrigin, CenterDirection, SidescrollerPlane);
		}

		devError("Tried to get world center of screen when no player is in fullscreen");
		return FVector();
	}

	// Will return the screen position of the closest point on the player (so top right for when the player is in the bottom left etc.). Use this to calculate the distance from the player to the screen
	FVector2D GetClosestPlayerScreenPos(bool bGetInnerMostPoint = true) const
	{
		FVector ScreenCenter = GetWorldCenterOfScreen();
		FTransform SplineTransform = SidescrollerTransform;
		FTransform ScreenTransform = FTransform(SplineTransform.Rotation, ScreenCenter);
		FVector PlayerScreenWorldSpace = ScreenTransform.InverseTransformPosition(Player.ActorCenterLocation);

		FVector PlayerLocationToCheck = Player.ActorCenterLocation;
		if(PlayerScreenWorldSpace.X != 0.0)
		{
			float Sign = Math::Sign(PlayerScreenWorldSpace.X);
			if(bGetInnerMostPoint)
				Sign = -Sign;

			PlayerLocationToCheck += SplineTransform.Rotation.ForwardVector * (Player.ScaledCapsuleRadius * Sign);
		}

		if(PlayerScreenWorldSpace.Z != 0.0)
		{
			float Sign = Math::Sign(PlayerScreenWorldSpace.Z);
			if(bGetInnerMostPoint)
				Sign = -Sign;

			PlayerLocationToCheck += SplineTransform.Rotation.UpVector * (Player.ScaledCapsuleHalfHeight * Sign);
		}

		FVector2D ScreenPos;
		SceneView::ProjectWorldToViewpointRelativePosition(Player, PlayerLocationToCheck, ScreenPos);
		return ScreenPos;
	}

	bool AreBothPlayersOnScreen() const
	{
		for(AHazePlayerCharacter Current : Game::Players)
		{
			if(!IsPlayerOnScreen(Current))
				return false;
		}

		return true;
	}

	bool IsPlayerOnScreen(AHazePlayerCharacter In_Player, bool bRequirePlayerFullyOnScreen = false) const
	{
		if(!IsInFullscreen())
			return false;

		FVector2D ScreenPos = SidescrollerComp[In_Player].GetClosestPlayerScreenPos(!bRequirePlayerFullyOnScreen);
		if(ScreenPos.X < 0.0 || ScreenPos.X > 1.0 || ScreenPos.Y < 0.0 || ScreenPos.Y > 1.0)
			return false;

		return true;
	}

	private void SetCollisionEnabledForPlayer(AHazePlayerCharacter In_Player, bool bCollisionEnabled)
	{
		if(bCollisionEnabled)
			EnableCollisionForPlayer(In_Player);
		else
			DisableCollisionForPlayer(In_Player);
	}

	private void EnableCollisionForPlayer(AHazePlayerCharacter In_Player)
	{
		if(CollisionEnabledForPlayer[In_Player])
			return;

		MoveComp[In_Player].RemoveMovementIgnoresActor(this);
		CollisionEnabledForPlayer[In_Player] = true;
	}

	private void DisableCollisionForPlayer(AHazePlayerCharacter In_Player)
	{
		if(!CollisionEnabledForPlayer[In_Player])
			return;

		MoveComp[In_Player].AddMovementIgnoresActors(this, EdgeColliders);
		CollisionEnabledForPlayer[In_Player] = false;
	}
}

UFUNCTION()
mixin void IslandEnterSidescrollerMode(AHazePlayerCharacter Player, AHazeActor SplineActor, bool bFullscreen = true, AHazeCameraActor InitialCamera = nullptr, float CameraBlendTime = 0.0, bool bTopCollider = true)
{
	auto SidescrollerComp = UIslandSidescrollerComponent::Get(Player);
	devCheck(SidescrollerComp != nullptr, "There isn't a sidescroller component on this player");
	SidescrollerComp.EnterSidescrollerMode(SplineActor, bFullscreen, InitialCamera, CameraBlendTime, bTopCollider);
}

UFUNCTION()
mixin void IslandExitSidescrollerMode(AHazePlayerCharacter Player)
{
	auto SidescrollerComp = UIslandSidescrollerComponent::Get(Player);
	devCheck(SidescrollerComp != nullptr, "There isn't a sidescroller component on this player");
	SidescrollerComp.ExitSidescrollerMode();
}

UFUNCTION(BlueprintPure)
mixin bool IslandIsInSidescrollerMode(AHazePlayerCharacter Player)
{
	auto SidescrollerComp = UIslandSidescrollerComponent::Get(Player);
	devCheck(SidescrollerComp != nullptr, "There isn't a sidescroller component on this player");
	return SidescrollerComp.IsInSidescrollerMode();
}

UFUNCTION(BlueprintCallable)
mixin void IslandAddEdgeColliderBlocker(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto SidescrollerComp = UIslandSidescrollerComponent::Get(Player);
	devCheck(SidescrollerComp != nullptr, "There isn't a sidescroller component on this player");
	SidescrollerComp.AddEdgeColliderBlocker(Instigator);
}

UFUNCTION(BlueprintCallable)
mixin void IslandRemoveEdgeColliderBlocker(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto SidescrollerComp = UIslandSidescrollerComponent::Get(Player);
	devCheck(SidescrollerComp != nullptr, "There isn't a sidescroller component on this player");
	SidescrollerComp.RemoveEdgeColliderBlocker(Instigator);
}