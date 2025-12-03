struct FTimeDilationEffect
{
	/**
	 * What time dilation multiplier to apply.
	 */
	UPROPERTY()
	float TimeDilation = 1.0;

	/**
	 * How long (in real time) to blend to the new time dilation.
	 */
	UPROPERTY()
	float BlendInDurationInRealTime = 0.0;

	/**
	 * If the effect is active for this long (real time), automatically end it.
	 * If negative, do not end automatically, only end when explicitly stopped.
	 */
	UPROPERTY()
	float MaxDurationInRealTime = -1.0;

	/**
	 * When stopped, how long (in real time) to blend to the normal time dilation.
	 */
	UPROPERTY()
	float BlendOutDurationInRealTime = 0.0;
};

namespace TimeDilation
{


/**
 * Start a time dilation effect and apply it to the time dilation for the entire world.
 */
UFUNCTION(Category = "Time Dilation")
void StartWorldTimeDilationEffect(FTimeDilationEffect Effect, FInstigator Instigator)
{
	UTimeDilationEffectSingleton Singleton = UTimeDilationEffectSingleton::Get();
	Singleton.StartTimeDilationEffect(nullptr, Effect, Instigator);
}

/**
 * Stop a time dilation effect that is being applied to the world
 */
UFUNCTION(Category = "Time Dilation")
void StopWorldTimeDilationEffect(FInstigator Instigator)
{
	UTimeDilationEffectSingleton Singleton = UTimeDilationEffectSingleton::Get();
	Singleton.StopTimeDilationEffect(nullptr, Instigator);
}

};

/**
 * Start a time dilation effect and apply it to the time dilation for the actor.
 */
UFUNCTION(Category = "Time Dilation")
mixin void StartActorTimeDilationEffect(AHazeActor Actor, FTimeDilationEffect Effect, FInstigator Instigator)
{
	UTimeDilationEffectSingleton Singleton = UTimeDilationEffectSingleton::Get();
	Singleton.StartTimeDilationEffect(Actor, Effect, Instigator);
}

/**
 * Stop a time dilation effect that is being applied to the world
 */
UFUNCTION(Category = "Time Dilation")
mixin void StopActorTimeDilationEffect(AHazeActor Actor, FInstigator Instigator)
{
	UTimeDilationEffectSingleton Singleton = UTimeDilationEffectSingleton::Get();
	Singleton.StopTimeDilationEffect(Actor, Instigator);
}