UCLASS(Abstract)
class USkylineBreakableEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBreak()
	{
	}
};

class ASkylineBreakable : ABreakableActor
{
	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent GravityBladeResponseComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipImpactResponseComponent GravityWhipImpactResponseComponent;

	UPROPERTY(EditAnywhere)
	float BladeHitForce = 8000.0;

	UPROPERTY(EditAnywhere)
	float ImpactScatter = 0.2;

	UPROPERTY(EditAnywhere)
	float ImpactPullback = 100.0;

	UPROPERTY(EditAnywhere)
	float WhipImpactForceScale = 0.5;

	UPROPERTY(EditAnywhere)
	float WhipImpactForce = 8000;

	UPROPERTY(EditAnywhere)
	bool bBladeBreakable = true;

	UPROPERTY(EditAnywhere)
	bool bWhipBreakable = true;

	UPROPERTY(EditAnywhere)
	float ImpactRadius = 250.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();	
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		GravityBladeResponseComponent.OnHit.AddUFunction(this, n"OnBladeHit");
		GravityWhipImpactResponseComponent.OnImpact.AddUFunction(this, n"OnWhipImpact");
	}

	UFUNCTION()
	private void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if (!bBladeBreakable)
			return;

		auto Player = Cast<AHazePlayerCharacter>(CombatComp.Owner);

		if (Player == nullptr)
			return;

		FVector PlayerLocation = Player.FocusLocation;

		FVector ImpactPoint;
		HitData.Component.GetClosestPointOnCollision(PlayerLocation, ImpactPoint);

		FVector ToPlayer = PlayerLocation - ImpactPoint;
		FVector AdjustedImpactPoint = ImpactPoint + ToPlayer.SafeNormal * ImpactPullback;
		FVector AdjustedImpactDirection = -ToPlayer.SafeNormal;

//		Debug::DrawDebugSphere(AdjustedImpactPoint, ImpactRadius, 24, FLinearColor::Red, 5.0, 2.0);
//		Debug::DrawDebugLine(ImpactPoint, ImpactPoint + ToPlayer, FLinearColor::Red, 5.0, 2.0);

		Break(AdjustedImpactPoint, ImpactRadius, AdjustedImpactDirection * BladeHitForce, ImpactScatter);
	}

	UFUNCTION()
	private void OnWhipImpact(FGravityWhipImpactData ImpactData)
	{
		if (!bWhipBreakable)
			return;

//		FVector PlayerLocation = Game::Zoe.ActorCenterLocation;

		FVector ImpactPoint = ImpactData.HitResult.ImpactPoint;

//		FVector ToPlayer = PlayerLocation - ImpactPoint;

		FVector AdjustedImpactPoint = ImpactPoint - ImpactData.ImpactVelocity.SafeNormal * ImpactPullback;

//		Debug::DrawDebugSphere(AdjustedImpactPoint, ImpactRadius, 24, FLinearColor::Red, 5.0, 2.0);
//		Debug::DrawDebugLine(ImpactPoint, ImpactPoint + ImpactData.ImpactVelocity.SafeNormal * 500.0, FLinearColor::Red, 5.0, 2.0);

		Break(AdjustedImpactPoint, ImpactRadius, ImpactData.ImpactVelocity.SafeNormal * WhipImpactForce, ImpactScatter);
	}

	UFUNCTION()
	void Break(FVector Location, float Radius, FVector Force, float Scatter)
	{
		BreakableComponent.BreakAt(Location, Radius, Force, Scatter);

		TArray<UTargetableComponent> Targetables;
		GetComponentsByClass(Targetables);
		for (auto Targetable : Targetables)
			Targetable.Disable(this);

		USkylineBreakableEventHandler::Trigger_OnBreak(this);
		BP_Break();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Break() { }
}