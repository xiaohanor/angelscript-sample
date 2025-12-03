
class AExampleBlockedActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent Mesh;

	// Turning functionality of with an instigator on the actor
	void ExampleBlockActor()
	{
		// Only the actors ticks are affected, NOT it's components
		AddActorTickBlock(this);
		RemoveActorTickBlock(this);

		// The entire actor and all it's component are affected
		AddActorVisualsBlock(this);
		RemoveActorVisualsBlock(this);

		// The entire actor and all it's components are affected
		AddActorCollisionBlock(this);
		RemoveActorCollisionBlock(this);
	}

	// Turning functionality of with an instigator on the component
	void ExampleBlockComponent()
	{
		// Component Tick
		Mesh.AddComponentTickBlocker(this);
		Mesh.RemoveComponentTickBlocker(this);

		//Component Visuals
		Mesh.AddComponentVisualsBlocker(this);
		Mesh.RemoveComponentVisualsBlocker(this);

		// Component Collision
		Mesh.AddComponentCollisionBlocker(this);
		Mesh.RemoveComponentCollisionBlocker(this);
	}

}