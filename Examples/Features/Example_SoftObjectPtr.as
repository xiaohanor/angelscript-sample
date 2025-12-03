
/**
 * Soft pointers are references to objects that are not necessarily loaded yet.
 * This can be used to create properties that reference actors in different sublevels.
 */
class AExample_SoftReference : AActor
{
	// Can select an actor in any sublevel
	UPROPERTY(EditAnywhere)
	TSoftObjectPtr<AActor> OtherActor;

	// Can reference a component class without always loading it
	UPROPERTY(EditAnywhere)
	TSoftClassPtr<UActorComponent> ComponentClass;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Check for the actor in a different level
		//  Note that it may be null here if this level is streamed in before the other one
		AActor Actor = OtherActor.Get();
		Print("Selected Actor: "+Actor);

		// Load the component class asynchronously now that we need it
		ComponentClass.LoadAsync(FOnSoftClassLoaded(this, n"OnComponentClassLoaded"));
	}

	UFUNCTION()
	void OnComponentClassLoaded(UClass LoadedClass)
	{
		Print("Loaded component class: "+LoadedClass);
	}
};