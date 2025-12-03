/*
 * A SubAnimInstance can be used as a parent class for a SubABP in Unreal.
 * SubABP's are used when a character needs to be able to transition between multiple ABPs.
 * For example our main playable characters uses SubABP's for: Movement, Jump, Falling etc.
 *
 * If you have a NPC it will in most cases be enough to create one base ABP with a state machine inside of that.
 *
 * To create a SubABP from this class in Unreal Engine:
 * Right click in the content browser: Animation > Animation Blueprint
 * Find the class, in this case 'FeatureAnimInstanceExample'. 
 * Select the skeleton this will be applied on (Base_Skeleton for our main playable characters).
 */


// Import the LocomotionFeature we want to read data from

// Any other imports, such as components

/*
 * Class name should always start with 'USubAnimInstance' followed by the name of the feature
 * It should also always inherit from the 'UHazeFeatureSubAnimInstance' class.
 */
class UFeatureAnimInstanceExample : UHazeFeatureSubAnimInstance
{

	/*
	 * Create a variable for the feature class
	 * This will be used to check if feature is already loaded or not.
	 *
	 * By adding 'BlueprintHidden' we make sure it's hidden in the editor.
	 */
    UPROPERTY(Transient, BlueprintHidden, NotEditable)
    ULocomotionFeatureExample CurrentFeature;


	/*
	 * Create a variable of the LocomotionFeatureData struct, that we later can access in the Animation Graph
	 * A variable must have UPROPERTY() above it for it to be exposed to Blueprint/Animation Graph.
	 * 
	 * By adding 'BlueprintReadOnly' to UPROPERTY() this variable cannot be edited from Blueprint, only read.
	 * By adding 'NotEditable' to UPROPERTY() the default value cannot be set in the ABP
	 */
    UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FLocomotionFeatureExampleAnimData AnimData;
	

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bExampleBoolean;
    
	USceneComponent MovementComp;

	float CustomBlendTime;


    /*
	 * BlueprintInitializeAnimation() will be called once when we enter this ABP
	 * Because this is a declared as a blueprint event in C++, UFUNCTION() needs to contain 'BlueprintOverride'
	 *
	 * This is a good place to get and save references to features, components, actors etc.
	 * Also a good place to reset variables if needed.
	 */
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		// Cast to the feature to get access to all of the data in the Data Asset.
		ULocomotionFeatureExample NewFeature = GetFeatureAsClass(ULocomotionFeatureExample);
		
		// If we already have the data loaded from a previous instance, skip updating it.
		if (CurrentFeature != NewFeature)
        {
			// Save the data in variables accessible from the ABP
            CurrentFeature = NewFeature;
            AnimData = NewFeature.AnimData;
        }

		// How to get a reference to a component on the Actor
		MovementComp = USceneComponent::Get(HazeOwningActor);

		/*
		 * Example of setting a custom blend time variable and then returning it in the GetBlendTime() function.
		 * Reason for doing this here on initialize is because a BoolParam cannot be consumed in a function that's constant (const).
		 */
		CustomBlendTime = 0.5;
		if (GetAnimBoolParam(n"SkipEnter", true))
			CustomBlendTime = 0;

    }


	/*
	 * GetBlendTime() will be called once after BlueprintInitializeAnimation()
	 * It expects a float variable to be returned that will then be used as a the BlendTime into this ABP
	 * Right now it only returns variable we set in Initialize, but you could do nested if statements etc. in here.
	 */
	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const 
	{
		return CustomBlendTime;
	}

    /*
	 * BlueprintUpdateAnimation() will be called every tick for as long as this ABP is active.
	 *
	 * DeltaTime is how long it took to draw the current frame. e.g. If you're running in stable 60FPS, the delta time will be 1/60.
	 * DeltaTime can be used to make sure certain calculations are frame dependent.
	 */
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		/*
		 * If the LocomotionFeature is invalid, no need to run the rest of the code.
		 * This is because the preview window in ABP editor also will try to run this code, which might result in errors.
		 */
        if (CurrentFeature == nullptr)
           return;

		// Example of how to fetch an AnimBoolParam
		bExampleBoolean = GetAnimBoolParam(n"Example", bConsume = true);

		/* 
		 * OwningActor is the AActor the ABP is currently running on.
		 * A lot of basic data can be found here, such as actor rotation, location, velocity etc.
		 */
		FVector ActorVelocity = HazeOwningActor.GetActorVelocity();

		float AirTime = CalculateSum(5.0, 3.0);

    }
	    

    /*
	 * CanTransitionFrom() will be called every tick as soon as another feature is being requested
	 * If false is returned, the character cannot leave this ABP and will be forced to stay.
	 * If true is returned, the character will transition out to another ABP.
	 */
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom() const
    {
		/*
		 * This would block the character from leaving the ABP for as long as the LocomotionTag "AirMovement" is called.
		 */
		if (LocomotionAnimationTag == n"AirMovement")
			return false;

		/*
		* If there is a state machine in the main anim graph this will return the name of the state it is currently in
		*/
		if (GetTopLevelGraphRelevantStateName() == n"Exit")
			return true;

		/*
		* If there is a state machine in the main anim graph this will return the anim time remaining for whatever state it is currently in
		*/
		if (GetTopLevelGraphRelevantAnimTimeRemaining() <= 0.0)
			return true;

		// If no rules above are blocking it from leaving, return true. 
        return true;
    }


	/*
	 * OnTransitionFrom() will be called when the character leaves this ABP,
	 * so in other words when CanTransitionFrom() returns true.
	 */
	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		/*
		 * Here we can e.g. check if we're going into a spesific feature by checking the LocomotionTag
		 * and if so set a BoolParam that controls e.g. BlendTime, skipping enters etc.
		 */
		if (LocomotionAnimationTag == n"Movement") {
			SetAnimBoolParam(n"SkipEnter", true);
		}
	}


	/*
	 * Example of how to hook up to an anim notify event set on e.g.
	 * OnStateEntered in the Animation Graph.
	 * The function name must be prefixed with AnimNotify_ and then
	 * followed by the event name.
	 */
	UFUNCTION()
	void AnimNotify_Example()
	{
		
	}


	/*
	 * Example of a custom function
	 */
	float CalculateSum(float X, float Y)
	{	
		return X + Y;
	}

}