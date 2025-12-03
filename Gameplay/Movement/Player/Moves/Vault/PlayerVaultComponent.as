
class UPlayerVaultComponent : UActorComponent
{
	AHazePlayerCharacter OwningPlayer;

	UPlayerVaultSettings Settings;
	UPlayerWallSettings WallSettings;

	protected EPlayerVaultState CurrentState = EPlayerVaultState::None;

	FPlayerVaultData Data;

	UPROPERTY(BlueprintReadOnly)
	FPlayerVaultAnimationData AnimData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);

		Settings = UPlayerVaultSettings::GetSettings(Cast<AHazeActor>(Owner));
		WallSettings = UPlayerWallSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

	EPlayerVaultState GetState() const property
	{
		return CurrentState;
	}

	void SetState(EPlayerVaultState NewState) property
	{
		CurrentState = NewState;
		AnimData.State = CurrentState;
	}

	// Returns true if the state completed was the active state (nothing else took over)
	bool StateCompleted(EPlayerVaultState CompletedState)
	{
		if (State == CompletedState)
		{
			ResetVault();
			return true;
		}
		return false;
	}

	void ResetVault()
	{
		State = EPlayerVaultState::None;
		Data.Reset();
		AnimData.Reset();
	}

	bool TraceForVault(AHazePlayerCharacter Player, FVector Direction, FPlayerVaultData& VaultData, bool bDebug = false)
	{
		if (Player == nullptr)
			return false;

		/*
			Test whether you should climb or vault over
			- Climb: Create two points (Edge and End)
			- Vault: Create three points (Edge, FarEdge and End)
		*/

		UPlayerMovementComponent MoveComp = UPlayerMovementComponent::Get(Player);

		VaultData.Reset();
		VaultData.Direction = Direction.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		VaultData.EnterSpeed = Math::Clamp(MoveComp.HorizontalVelocity.Size(), 500.0, 750.0);

		if(VaultData.Direction.IsNearlyZero())
			return false;

		if(Settings.EnterDistanceMax <= 0)
			return false;

		/* Near Wall Trace */
		FHitResult NearWallTraceHit;
		{
			FHazeTraceSettings NearWallTraceSettings = Trace::InitFromMovementComponent(MoveComp);
			//NearWallTraceSettings.UseSphereShape(Settings.WallTraceSphereRadius);
			NearWallTraceSettings.UseLine();

			if (bDebug)
				NearWallTraceSettings.DebugDraw(4.0);
			
			FVector TraceStart = Player.ActorCenterLocation;
			FVector TraceEnd = TraceStart;
			//TraceEnd += Direction.GetSafeNormal() * Math::Max(Settings.EnterDistanceMax - Settings.WallTraceSphereRadius, 0.0);
			TraceEnd += VaultData.Direction.GetSafeNormal() * Settings.EnterDistanceMax;
	
			NearWallTraceHit = NearWallTraceSettings.QueryTraceSingle(TraceStart, TraceEnd);
		}

		if (!NearWallTraceHit.bBlockingHit)
			return false;
		if (!NearWallTraceHit.Component.HasTag(ComponentTags::Vaultable))
			return false;

		const FRotator VaultRotationComparand = FRotator::MakeFromZX(MoveComp.WorldUp, Direction);

		const FVector NearWallRight = Player.MovementWorldUp.CrossProduct(NearWallTraceHit.ImpactNormal).GetSafeNormal();
		const FRotator NearWallRotation = FRotator::MakeFromXY(NearWallTraceHit.ImpactNormal, NearWallRight);
		
		// Pitch test
		// Question: Should we even care about the pitch of the near wall in a vault? Should we be super open? Should we only treat it like a flat(ish) surface on the top and not care about the walls on the near/far side?
		const FVector NearWallPitchVector = NearWallRotation.UpVector.ConstrainToPlane(VaultRotationComparand.RightVector).GetSafeNormal();
		const float NearWallPitchAngle = Math::RadiansToDegrees(NearWallPitchVector.AngularDistance(VaultRotationComparand.UpVector) * Math::Sign(NearWallPitchVector.DotProduct(VaultRotationComparand.ForwardVector))); 
		if (NearWallPitchAngle < WallSettings.WallPitchMinimum - KINDA_SMALL_NUMBER
				|| NearWallPitchAngle > WallSettings.WallPitchMaximum + KINDA_SMALL_NUMBER)
			return false;

		/* NearTop Trace
			- First trace to find a surface to vault on to
			- Then test whether the player can fit there
		*/
		FHitResult NearTopTraceHit;
		{
			FHazeTraceSettings NearTopTraceSettings = Trace::InitFromMovementComponent(MoveComp);
			NearTopTraceSettings.UseLine();

			if (bDebug)
			{
				NearTopTraceSettings.DebugDraw(4.0);

				// Draw the maximum horizontal range
					// Debug::DrawDebugLine(TopTraceForwardInitialPosition, TopTraceForwardInitialPosition + TopTraceForwardReach, FLinearColor::Blue, 1.0, 0.0);
					// FVector DownReach = -Player.MovementWorldUp * (Settings.TopTraceUpwardsReach + Settings.TopTraceDownwardsReach);
					// Debug::DrawDebugLine(TopTraceForwardInitialPosition + DownReach, TopTraceForwardInitialPosition + DownReach + TopTraceForwardReach, FLinearColor::Blue, 1.0, 0.0);
			}

			FVector ToWall = (NearWallTraceHit.ImpactPoint - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp);
			
			FVector TopTraceStartLocation = Player.ActorLocation + ToWall + (VaultData.Direction * Settings.TopTraceDepth);
			FVector TopTraceEndLocation = TopTraceStartLocation + MoveComp.WorldUp * Settings.HeightMin;
			TopTraceStartLocation += Player.MovementWorldUp * Settings.HeightMax;
			
			NearTopTraceHit = NearTopTraceSettings.QueryTraceSingle(TopTraceStartLocation, TopTraceEndLocation);
		}

		if (NearTopTraceHit.bStartPenetrating)
			return false;
		if (!NearTopTraceHit.bBlockingHit)
			return false;
		if (!NearTopTraceHit.Component.HasTag(ComponentTags::Vaultable))
			return false;

		const FRotator NearTopRotation = FRotator::MakeFromZX(NearTopTraceHit.ImpactNormal, VaultData.Direction);

		// Pitch test
		const FVector NearTopPitchVector = NearTopRotation.UpVector.ConstrainToPlane(VaultRotationComparand.RightVector).GetSafeNormal();
		const float NearTopPitchAngle = Math::RadiansToDegrees(NearTopPitchVector.AngularDistance(VaultRotationComparand.UpVector) * Math::Sign(NearTopPitchVector.DotProduct(VaultRotationComparand.ForwardVector)));
		if (NearTopPitchAngle < WallSettings.TopPitchMinimum - KINDA_SMALL_NUMBER
				|| NearTopPitchAngle > WallSettings.TopPitchMaximum + KINDA_SMALL_NUMBER)
			return false;

		// Roll test
		const FVector NearTopRollVector = NearTopRotation.UpVector.ConstrainToPlane(VaultRotationComparand.ForwardVector).GetSafeNormal();
		const float NearTopRollAngle = Math::RadiansToDegrees(NearTopRollVector.AngularDistance(VaultRotationComparand.UpVector)); 
		if (!Math::IsNearlyEqual(NearTopRollAngle, 0.0, WallSettings.TopRollMaximum + 0.01))
			return false;
						
		FVector WallToTop = NearTopTraceHit.ImpactPoint - NearWallTraceHit.ImpactPoint;
		VaultData.NearEdgeLocation = NearWallTraceHit.ImpactPoint + (NearWallRotation.UpVector * (WallToTop.DotProduct(NearWallRotation.UpVector)));
		VaultData.NearEdgePlayerLocation = VaultData.NearEdgeLocation - (MoveComp.WorldUp * Player.CapsuleComponent.CapsuleHalfHeight);
		if (bDebug)
			Debug::DrawDebugSphere(VaultData.NearEdgeLocation, 10.0, 10, FLinearColor::Yellow, 1.0, 4.0);
		
		// TODO: Hook up jog and sprint top speeds to the actual settings asset
		VaultData.EnterDistance = (VaultData.NearEdgeLocation - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp).Size();
		VaultData.EnterDuration = Math::Clamp(VaultData.EnterDistance / VaultData.EnterSpeed, Settings.EnterDurationMin, Settings.EnterDurationMax);

		/* Now we test whether we should vault, or climb, yo */
		FHitResult FarWallTraceHit;
		{
			FHazeTraceSettings FarWallTraceSettings = Trace::InitFromMovementComponent(MoveComp);
			FarWallTraceSettings.UseLine();
			if (bDebug)
				FarWallTraceSettings.DebugDraw(4.0);

			FVector TraceStart = NearWallTraceHit.ImpactPoint + Direction * Settings.DistanceMax;
			FVector TraceEnd = NearWallTraceHit.ImpactPoint;

			FarWallTraceHit = FarWallTraceSettings.QueryTraceSingle(TraceStart, TraceEnd);

			/*
				I should probably do a few traces backwards instead of one big one for cases like:
				______    __  __________
				|    |    ||  |        |
			*/
		}

		// If you don't get a blocking hit from this test, I will quit Hazelight. It shouldn't be possible
		if (!FarWallTraceHit.bBlockingHit)
			return false;
		if (FarWallTraceHit.bStartPenetrating)
		{
			// Could be a raised platform. Test for climb (find EndLocation)

			FHazeTraceSettings ClimbTraceSettings = Trace::InitFromMovementComponent(MoveComp);
			ClimbTraceSettings.UseLine();
			if (bDebug)
				ClimbTraceSettings.DebugDraw(4.0);

			const float ClimbDistance = Settings.ClimbDuration * VaultData.EnterSpeed;
			FVector ClimbTraceStartLocation = VaultData.NearEdgeLocation + (VaultData.Direction * ClimbDistance) + (MoveComp.WorldUp * 40.0);
			FVector ClimbTraceEndLocation = VaultData.NearEdgeLocation + (VaultData.Direction * ClimbDistance) - (MoveComp.WorldUp * 40.0);
			
			FHitResult ClimbHit = ClimbTraceSettings.QueryTraceSingle(ClimbTraceStartLocation, ClimbTraceEndLocation);
			if (ClimbHit.bStartPenetrating)
				return false;
			if (!ClimbHit.bBlockingHit)
				return false;

			VaultData.VaultExitFloorHit = ClimbHit;
			VaultData.EndLocation = ClimbHit.ImpactPoint;
			if (bDebug)
				Debug::DrawDebugSphere(VaultData.EndLocation, 10.0, 10, FLinearColor::Yellow, 1.0, 4.0);

			VaultData.Mode = EPlayerVaultMode::Climb;
			VaultData.bHasCompleteData = true;
		}
		else
		{
			// Test for vault (find FarEdge and End locations)
			FHitResult FarTopTraceHit;
			{
				FHazeTraceSettings FarTopTraceSettings = Trace::InitFromMovementComponent(MoveComp);
				FarTopTraceSettings.UseLine();

				if (bDebug)
					FarTopTraceSettings.DebugDraw(4.0);
		
				FVector TraceStart = FarWallTraceHit.ImpactPoint - (Direction * Settings.TopTraceDepth);
				FVector TraceEnd = TraceStart;
				TraceStart += Player.MovementWorldUp * Settings.HeightMax;
				
				FarTopTraceHit = FarTopTraceSettings.QueryTraceSingle(TraceStart, TraceEnd);
			}

			if (!FarTopTraceHit.bBlockingHit)
				return false;

			const FVector FarWallRight = MoveComp.WorldUp.CrossProduct(FarWallTraceHit.ImpactNormal).GetSafeNormal();
			const FRotator FarWallRotation = FRotator::MakeFromXY(FarWallTraceHit.ImpactNormal, FarWallRight);
			
			FVector FarWallToTop = FarTopTraceHit.ImpactPoint - FarWallTraceHit.ImpactPoint;
			VaultData.FarEdgeLocation = FarWallTraceHit.ImpactPoint + (FarWallRotation.UpVector * (FarWallToTop.DotProduct(FarWallRotation.UpVector)));
			VaultData.FarEdgePlayerLocation = VaultData.FarEdgeLocation - (MoveComp.WorldUp * Player.CapsuleComponent.CapsuleHalfHeight);
			if (bDebug)
				Debug::DrawDebugSphere(VaultData.FarEdgeLocation, 10.0, 10, FLinearColor::Yellow, 1.0, 4.0);
			
			const float VaultDistance = (VaultData.NearEdgeLocation - VaultData.FarEdgeLocation).Size();
			if (VaultDistance > Settings.SlideDistanceMin)
			{
				VaultData.Mode = EPlayerVaultMode::Slide;
				VaultData.SlideDuration = VaultDistance / VaultData.EnterSpeed;
			}
			else
				VaultData.Mode = EPlayerVaultMode::Vault;

			// Trace for the end location for the slide/vault
			FHitResult EndTraceHit;
			{
				FHazeTraceSettings EndTraceSettings = Trace::InitFromMovementComponent(MoveComp);
				EndTraceSettings.UseLine();

				if (bDebug)
					EndTraceSettings.DebugDraw(4.0);
		
				FVector TraceStart = VaultData.NearEdgeLocation;
				if (VaultData.Mode == EPlayerVaultMode::Slide)
					TraceStart = VaultData.FarEdgeLocation;
				TraceStart += VaultData.Direction * VaultData.EnterSpeed * Settings.ExitDuration;

				FVector TraceEnd = TraceStart;
				TraceEnd -= MoveComp.WorldUp * (Settings.HeightMax + 50.0);
				
				EndTraceHit = EndTraceSettings.QueryTraceSingle(TraceStart, TraceEnd);
			}
			if (!EndTraceHit.bBlockingHit)
				return false;
			// TODO: Height check
			VaultData.VaultExitFloorHit = EndTraceHit;
			VaultData.EndLocation = EndTraceHit.ImpactPoint;
			VaultData.bHasCompleteData = true;
			if (bDebug)
				Debug::DrawDebugSphere(VaultData.EndLocation, 10.0, 10, FLinearColor::Yellow, 1.0, 4.0);
		}

		return VaultData.bHasCompleteData;
	}
}

struct FPlayerVaultData
{
	EPlayerVaultState State = EPlayerVaultState::None;
	EPlayerVaultMode Mode = EPlayerVaultMode::Vault;
	bool bHasCompleteData = false;
	FVector Direction;

	FVector NearEdgeLocation;
	FVector FarEdgeLocation;
	FVector NearEdgePlayerLocation;
	FVector FarEdgePlayerLocation;
	FVector EndLocation;

	/* Enter */
	bool bEnterComplete = false;
	bool bSlideComplete = false;
	float EnterSpeed = 0.0;
	float EnterDistance = 0.0;
	float EnterDuration = 0.1;
	bool bEnteredInSprint = false;

	/* Slide */
	float SlideDuration = 0.0;

	/* Exit */
	FHitResult VaultExitFloorHit;

	bool HasValidData()
	{
		return bHasCompleteData; 
	}

	// Resets the stored data
	void Reset()
	{
		bHasCompleteData = false;
		State = EPlayerVaultState::None;
		bEnterComplete = false;
	}
}

struct FPlayerVaultAnimationData
{
	UPROPERTY()
	EPlayerVaultState State = EPlayerVaultState::None;

	UPROPERTY()
	bool bEnterFinished = false;

	UPROPERTY()
	bool bIsMirrored = false;

	UPROPERTY()
	FVector2D EnterDistanceSpeed;

	void Reset()
	{
		State = EPlayerVaultState::None;
	}
}

enum EPlayerVaultState
{
	None,
	Enter,
	Climb,
	Slide,
	Exit
}

enum EPlayerVaultMode
{
	Climb,
	Vault,
	Slide
}