struct FIslandPunchotronProjectileImpactParams
{
	FIslandPunchotronProjectileImpactParams(FVector Location)
	{
		HitLocation = Location;
	}

	UPROPERTY()
	FVector HitLocation;
}

struct FIslandPunchotronJumpAttackImpactParams
{
	FIslandPunchotronJumpAttackImpactParams(FVector Location)
	{
		HitLocation = Location;
	}

	UPROPERTY()
	FVector HitLocation;
}

struct FIslandPunchotronSpinningAttackTelegraphingParams
{
	FIslandPunchotronSpinningAttackTelegraphingParams(USceneComponent Location, AHazeActor InTargetActor)
	{
		VFXLocation = Location;
		TargetActor = InTargetActor;
	}

	UPROPERTY()
	USceneComponent VFXLocation;

	UPROPERTY()
	AHazeActor TargetActor;
}

struct FIslandPunchotronHaywireAttackTelegraphingParams
{
	FIslandPunchotronHaywireAttackTelegraphingParams(USceneComponent Location, AHazeActor InTargetActor, USceneComponent EndLocation)
	{
		VFXLocation = Location;
		TargetActor = InTargetActor;
		BeamEndLocation = EndLocation;
	}

	UPROPERTY()
	USceneComponent VFXLocation;

	UPROPERTY()
	USceneComponent BeamEndLocation;

	UPROPERTY()
	AHazeActor TargetActor;
}

struct FIslandPunchotronWheelchairKickAttackTelegraphingParams
{
	FIslandPunchotronWheelchairKickAttackTelegraphingParams(USceneComponent Location, AHazeActor InTargetActor, USceneComponent EndLocation)
	{
		VFXLocation = Location;
		TargetActor = InTargetActor;
		BeamEndLocation = EndLocation;
	}

	UPROPERTY()
	USceneComponent VFXLocation;

	UPROPERTY()
	USceneComponent BeamEndLocation;

	UPROPERTY()
	AHazeActor TargetActor;
}
struct FIslandPunchotronEyeTelegraphingParams
{
	FIslandPunchotronEyeTelegraphingParams(USceneComponent Location)
	{
		VFXLocation = Location;
	}

	UPROPERTY()
	USceneComponent VFXLocation;
}


struct FIslandPunchotronJetsParams
{
	FIslandPunchotronJetsParams(USceneComponent LeftLocation, USceneComponent RightLocation)
	{
		LeftFootLocation = LeftLocation;
		RightFootLocation = RightLocation;
	}

	UPROPERTY()
	USceneComponent LeftFootLocation;

	UPROPERTY()
	USceneComponent RightFootLocation;
}

struct FIslandPunchotronSingleJetParams
{
	FIslandPunchotronSingleJetParams(USceneComponent _JetLocation)
	{
		JetLocation = _JetLocation;
	}

	UPROPERTY()
	USceneComponent JetLocation;
}


struct FIslandPunchotronFlameThrowerParams
{
	FIslandPunchotronFlameThrowerParams(USceneComponent LeftLocation, USceneComponent RightLocation)
	{
		LeftFootLocation = LeftLocation;
		RightFootLocation = RightLocation;
	}

	UPROPERTY()
	USceneComponent LeftFootLocation;

	UPROPERTY()
	USceneComponent RightFootLocation;
}

struct FIslandPunchotronExhaustVentParams
{
	FIslandPunchotronExhaustVentParams(USceneComponent _ExhaustVentLocation)
	{
		ExhaustVentLocation = _ExhaustVentLocation;
	}

	UPROPERTY()
	USceneComponent ExhaustVentLocation;
}

struct FIslandPunchotronSwipeParams
{
	FIslandPunchotronSwipeParams(USceneComponent LeftLocation, USceneComponent RightLocation)
	{
		LeftBladeLocation = LeftLocation;
		RightBladeLocation = RightLocation;
	}

	UPROPERTY()
	USceneComponent LeftBladeLocation;

	UPROPERTY()
	USceneComponent RightBladeLocation;
}

struct FIslandPunchotronProximityAttackTelegraphingParams
{
	FIslandPunchotronProximityAttackTelegraphingParams(USceneComponent Location, AHazeActor InTargetActor)
	{
		VFXLocation = Location;
		TargetActor = InTargetActor;
	}

	UPROPERTY()
	USceneComponent VFXLocation;

	UPROPERTY()
	AHazeActor TargetActor;
}

struct FIslandPunchotronOnLandedParams
{
	FIslandPunchotronOnLandedParams(float _IntensityFactor)
	{
		IntensityFactor = _IntensityFactor;
	}

	UPROPERTY()
	float IntensityFactor = 1.0;
}

UCLASS(Abstract)
class UIslandPunchotronEffectHandler : UHazeEffectEventHandler
{
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartDying() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeath() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDamage(FIslandPunchotronProjectileImpactParams Params) {}	

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStunned() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnJump() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnLanded(FIslandPunchotronOnLandedParams Params) {}

	// Deprecated
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnJumpAttackImpact(FIslandPunchotronJumpAttackImpactParams Params) {}

	// Deprecated
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnSpinningAttackTelegraphingStart(FIslandPunchotronSpinningAttackTelegraphingParams Params) {}
	
	// Deprecated
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnSpinningAttackTelegraphingStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnCobraAttackTelegraphStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnCobraAttackBrakeStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnHaywireAttackTelegraphingStart(FIslandPunchotronHaywireAttackTelegraphingParams Params) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnHaywireAttackTelegraphingStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnKickAttackTelegraphStart() {}

	// Deprecated
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnWheelchairKickAttackTelegraphingStart(FIslandPunchotronWheelchairKickAttackTelegraphingParams Params) {}
	
	// Deprecated
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnWheelchairKickAttackTelegraphingStop() {}

	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnEyeTelegraphingStart(FIslandPunchotronEyeTelegraphingParams Params) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnEyeTelegraphingStop() {}


	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnLeftSwipe(FIslandPunchotronSwipeParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnRightSwipe(FIslandPunchotronSwipeParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnSawbladeAttackSwing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnProximityAttackTelegraphingStart(FIslandPunchotronProximityAttackTelegraphingParams Params) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnProximityAttackTelegraphingStop() {}


	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnJetsStart(FIslandPunchotronJetsParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnJetsStop() {}


	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnSmallJetsStart(FIslandPunchotronJetsParams Params) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnSmallJetSingleStart(FIslandPunchotronSingleJetParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnSmallJetsStop() {}


	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnSkateLeftStart(FIslandPunchotronSingleJetParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnSkateLeftEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnSkateRightStart(FIslandPunchotronSingleJetParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnSkateRightEnd() {}


	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnFlameThrowerStart(FIslandPunchotronFlameThrowerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnFlameThrowerStop() {}

	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnExhaustVentStart(FIslandPunchotronExhaustVentParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnExhaustVentStop() {}

}