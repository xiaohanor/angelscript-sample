
namespace DevTogglesMovement
{
	const FHazeDevToggleCategory MovementCategory = FHazeDevToggleCategory(n"Movement");

	namespace Jump
	{
		const FHazeDevToggleBoolPerPlayer AutoAlwaysJump;
	}

	namespace Dash
	{
		const FHazeDevToggleBoolPerPlayer AutoAlwaysDash;
	}

	namespace Move
	{
		const FHazeDevToggleBoolPerPlayer AutoRunInCircles;
	}

	namespace Knockdown
	{
		const FHazeDevToggleBool DebugDraw;
	}
}
