UCLASS(Abstract)
class USanctuaryCentipedeSlidingLavaEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartFalling() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact() {}
}

class ASanctuaryCentipedeSlidingLava : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LavaRoot;

	UPROPERTY(DefaultComponent, Attach = LavaRoot)
	UNiagaraComponent VFXComp;
	default VFXComp.RelativeRotation = FRotator(0.0, 180.0, 0.0);

	UPROPERTY(DefaultComponent)
	USanctuaryLavaApplierComponent LavaComp;
	default LavaComp.bOverlapMesh = false;
	default LavaComp.bOverlapTrigger = true;
	default LavaComp.DamagePerSecond = 0.5;
	default LavaComp.DamageDuration = 0.2;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueueComp;

	UPROPERTY()
	FRuntimeFloatCurve FallCurve;

	UPROPERTY()
	FRuntimeFloatCurve ScaleCurve;

	ASanctuaryCentipedeSlidingLavaManager Manager;

	FVector SlopeDirection;

	UPROPERTY(Category = Settings, EditAnywhere)
	float FallSpeed = 300.0;

	float SpeedMultiplier = 1.0;

	bool bFalling = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		// Ignore centipede body collisions for movement
		AddActorTag(CentipedeTags::IgnoreCentipedeBody);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SlopeDirection = -AttachParentActor.ActorUpVector;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorWorldOffset(SlopeDirection * FallSpeed * DeltaSeconds * SpeedMultiplier);
		//Debug::DrawDebugSphere(Root.WorldLocation, LavaComp.BurnBodyRadius, 12, FLinearColor::Green, 10, 0.1);

		if(HasControl() && ActorRelativeLocation.Z <= 0.0 && IsValid(Manager) && !bFalling)
		{
			bFalling = true;
			NetDrop();
		}
	}

	UFUNCTION(NetFunction)
	private void NetDrop()
	{	
		bFalling = true;
		BP_StartFall();

		ActionQueueComp.Empty();
		ActionQueueComp.Duration(2.0, this, n"UpdateBottomFall");
		ActionQueueComp.Event(this, n"Reset");
		ActionQueueComp.Duration(2.0, this, n"UpdateTopFall");
		ActionQueueComp.Event(this, n"Impact");
		ActionQueueComp.Duration(1.0, this, n"UpdateAccelerate");

		USanctuaryCentipedeSlidingLavaEventHandler::Trigger_OnStartFalling(this);
	}

	UFUNCTION()
	private void UpdateBottomFall(float Alpha)
	{
		SpeedMultiplier = 1.0;
		float ScaleAlpha = FallCurve.GetFloatValue(Alpha);
		float ScaleMultiplier = Math::Lerp(1.0, 0.5, ScaleAlpha);
		float ZScale = 1 / ScaleMultiplier;

		LavaRoot.SetRelativeScale3D(FVector(ScaleMultiplier, ScaleMultiplier, ZScale));
		
		float FallAlpha = FallCurve.GetFloatValue(Alpha);
		LavaRoot.SetWorldLocation(ActorLocation - FVector::UpVector * Math::Lerp(0.0, 3000.0, FallAlpha));
	}

	UFUNCTION()
	private void Reset()
	{
		AddActorWorldOffset(-SlopeDirection * Manager.SlideLength);

		float ScaleAlpha = ScaleCurve.GetFloatValue(0.0);
		float ZScale = 1 / ScaleAlpha;
		LavaRoot.SetRelativeScale3D(FVector(ScaleAlpha, ScaleAlpha, ZScale));
		SpeedMultiplier = 0.0;
	}

	UFUNCTION()
	private void UpdateTopFall(float Alpha)
	{
		float FallAlpha = FallCurve.GetFloatValue(Alpha);
		LavaRoot.SetWorldLocation(ActorLocation + FVector::UpVector * Math::Lerp(3000.0, 0.0, FallAlpha));
	}

	UFUNCTION()
	private void UpdateAccelerate(float Alpha)
	{
		float ScaleAlpha = ScaleCurve.GetFloatValue(Alpha);
		float ScaleMultiplier = Math::Lerp(0.5, 1.0, ScaleAlpha);
		float ZScale = 1 / ScaleMultiplier;

		LavaRoot.SetRelativeScale3D(FVector(ScaleMultiplier, ScaleMultiplier, ZScale));

		SpeedMultiplier = Math::Lerp(0.2, 1.0, Alpha);
	}

	UFUNCTION()
	private void Impact()
	{
		bFalling = false;
		BP_Impact();
		USanctuaryCentipedeSlidingLavaEventHandler::Trigger_OnImpact(this);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_StartFall(){}

	UFUNCTION(BlueprintEvent)
	private void BP_Impact(){}
};