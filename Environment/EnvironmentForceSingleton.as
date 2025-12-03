
/**
 * 
 * Manager that applies forces to registered actors. The actors 
 * subscribe on begin play and then the user applies one force 
 * here which is then propagated to everything.
 * 
 * @TODO: hmm note quite sure if singleton is the right thing to do here...
 * ...a cheaper solution is probably to write the force to a common source
 * that everything reads from instead...
 */

class UEnvironmentForceSingleton : UHazeSingleton
{
	private TArray<AEnvironmentCable> Cables;
	private TArray<AEnvironmentChain> Chains;
	private TArray<AEnvironmentSwing> Swings;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// nothing for now..
	}

	void RegisterCable(AEnvironmentCable Cable)
	{
		Cables.AddUnique(Cable);
	}

	void UnregisterCable(AEnvironmentCable Cable)
	{
		Cables.RemoveSingleSwap(Cable);
	}

	void RegisterChain(AEnvironmentChain Chain)
	{
		Chains.AddUnique(Chain);
	}

	void UnregisterChain(AEnvironmentChain Chain)
	{
		Chains.RemoveSingleSwap(Chain);
	}

	void RegisterSwing(AEnvironmentSwing Swing)
	{
		Swings.AddUnique(Swing);
	}

	void UnregisterSwing(AEnvironmentSwing Swing)
	{
		Swings.RemoveSingleSwap(Swing);
	}

	void ApplyShockwaveForce(const FEnvironmentShockwaveForceData& Shockwave)
	{
		// SWINGS
		for(auto IterSwing : Swings)
			IterSwing.ApplyShockwaveForce(Shockwave);

		// CHAINS
		for(auto IterChain : Chains)
			IterChain.ApplyShockwaveForce(Shockwave);

		// CABLES
		for(auto IterCable : Cables)
			IterCable.AddShockwaveForce(Shockwave);

		// Debug::DrawDebugSphere(
		// 	Shockwave.Epicenter,
		// 	Shockwave.OuterRadius,
		// 	32,
		// 	FLinearColor::Red,
		// 	20,
		// 	0
		// );
	}

};

namespace Environment
{
	UEnvironmentForceSingleton GetForceEmitter()
	{
		return Game::GetSingleton(UEnvironmentForceSingleton);
	}

	UFUNCTION(BlueprintCallable, Category = "Environment", DisplayName = "Apply Environment Shockwave Force" , Meta = (AutoSplit = "Data"))
	void ApplyShockwaveForce(const FEnvironmentShockwaveForceData& Data)
	{
		GetForceEmitter().ApplyShockwaveForce(Data);
	}
};

USTRUCT()
struct FEnvironmentShockwaveForceData
{
	// how to scale the force inbetween the radii
	UPROPERTY()
	ERadialImpulseFalloff FallOff = ERadialImpulseFalloff::RIF_Linear;

	UPROPERTY()
	FVector Epicenter = FVector::ZeroVector;

	// size of the force
	UPROPERTY()
	float Strength = 1000;

	// objects outside this radius will not get hit
	UPROPERTY()
	float OuterRadius = 2000;
	
	// objects within this radius will not get hit
	UPROPERTY()
	float InnerRadius = 1000;

	// optional instigator for debugging or if you need to find and remove a force after adding it
	UPROPERTY(AdvancedDisplay)
	FInstigator OptionalInstigator;

	FVector CalculateForceForTarget(const FVector& Target) const
	{
		FVector ToTarget = Target - Epicenter;
		float ToTargetDistance = ToTarget.Size();

		// only apply shockwave to stuff that are trapped within
		if(ToTargetDistance < InnerRadius || ToTargetDistance > OuterRadius)
			return FVector::ZeroVector;

		float ForceMagnitude = Strength;
		if(FallOff == ERadialImpulseFalloff::RIF_Linear)
			ForceMagnitude *= Math::NormalizeToRange(ToTargetDistance, InnerRadius, OuterRadius);

		FVector ToTargetDirection = FVector(1,0,0);
		if(ToTargetDistance > KINDA_SMALL_NUMBER)
			ToTargetDirection = ToTarget.GetUnsafeNormal();

		ToTargetDirection = Math::GetRandomConeDirection(ToTargetDirection, PI/16.0);

		// Debug::DrawDebugLine(
		// 	Target,
		// 	Target + ToTargetDirection*1000.0,
		// 	FLinearColor::Yellow,
		// 	10,1
		// );

		FVector Force = ToTargetDirection * ForceMagnitude;

		return Force;
	}
};