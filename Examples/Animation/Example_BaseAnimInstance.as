/*
 * A base animInstance should be used for all characters that only run one ABP (such as an NPC).
 * They can also be used as a base and then have a SubABP be played on top of it.
 *
 * To create an ABP from this class in Unreal Engine:
 * Right click in the content browser: Animation > Animation Blueprint
 * Find the class, in this case 'AnimInstanceExample'. 
 * Select the skeleton this will be applied on and click OK.
 */

// Example of importing an actor

/*
 * Class name should always start with 'UAnimInstance' followed by the name of the actor/character
 * It should also always inherit from the 'UHazeAnimInstanceBase' class.
 */
class UAnimInstanceExample : UHazeAnimInstanceBase
{
    /* 
	 * For base animInstances that doesn't use multiple features, we can create the animation slots here, 
	 * instead of creating a LocomotionFeature/Data Asset.The animation uAssets can then 
	 * be entered in the ABP under 'Class Defaults' (in the top toolbar, next to Play)
	 * 
	 * By adding 'BlueprintReadOnly' to UPROPERTY() this variable cannot be edited in Blueprint, only read.
	 */
    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Idle;

	// By addning 'NotEditable' to UPROPERTY() the default value cannot be set in the ABP
	UPROPERTY(BlueprintReadOnly, NotEditable)
	int ExampleVariable;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bExampleBoolean;
    
	AExampleActorType ActorReference;
	

    /*
	 * BlueprintInitializeAnimation() will be called once when we enter this ABP
	 * Because this is declared as a blueprint event in C++, UFUNCTION() needs to contain 'BlueprintOverride'
	 *
	 * This is a good place to get and save references to actors, components etc.
	 * Also a good place to reset variables if needed.
	 */
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		// Get a reference to the actor using this ABP
		ActorReference = Cast<AExampleActorType>(HazeOwningActor);
    }


    /* 
	 * BlueprintUpdateAnimation() will be called every tick
	 *
	 * DeltaTime is how long it took to draw the current frame. e.g. If you're running in stable 60FPS, the delta time will be 1/60.
	 * DeltaTime can be used to make sure certain calculations are frame dependent.
	 */
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		/*
		 * If the actor reference is invalid, no need to run the rest of the code.
		 * This is because the preview window in the ABP editor also will try to run this code, which might result in errors.
		 */
		if (ActorReference == nullptr)
			return;

		// Example of saving a variable from the actor to a local variable exposed in the animation graph
		ExampleVariable = ActorReference.ExampleValue;

		// Example of how to fetch an AnimBoolParam
		bExampleBoolean = GetAnimBoolParam(n"Example", bConsume = true);

    }


	/*
	 * Example of a custom function
	 * Right now it only returns a random value between 0 - 5
	 */
	float GetRandomStartTime()
	{
		return Math::RandRange(0.0, 5.0);
	}

}